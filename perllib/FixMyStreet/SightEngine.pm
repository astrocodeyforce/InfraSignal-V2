package FixMyStreet::SightEngine;

use strict;
use warnings;

use LWP::UserAgent;
use JSON::MaybeXS;
use Try::Tiny;
use FixMyStreet;
use mySociety::Locale;

=head1 NAME

FixMyStreet::SightEngine - Comprehensive image moderation via SightEngine API

=head1 DESCRIPTION

Integrates with SightEngine (https://sightengine.com) to automatically
moderate user-uploaded photos. Covers ALL available visual models:

  Standard Moderation:
    - Nudity & adult content (nudity-2.1)
    - Violence (violence)
    - Weapons (weapon)
    - Hate & offensive signs (offensive-2.0)
    - Gore & disgusting (gore-2.0)
    - Self-harm (self-harm)

  Restricted Content:
    - Recreational & medical drugs (recreational_drug)
    - Alcohol (alcohol)
    - Smoking & tobacco (tobacco)
    - Gambling (gambling)
    - Money & banknotes (money)

  Text Analysis in Images:
    - Text moderation / OCR profanity (text-content)

  AI Detection:
    - AI-generated images (genai)

  Quality:
    - Image quality (quality)

  Near-Duplicate Detection:
    - Duplicate/spam image detection via Image Lists

Fail-open design: if the API is unreachable or errors, photos are allowed
through so uploads are not blocked by API issues.

=head1 CONFIGURATION

Add to conf/general.yml:

    SIGHTENGINE_ENABLED: 1
    SIGHTENGINE_API_USER: '<your-api-user>'
    SIGHTENGINE_API_SECRET: '<your-api-secret>'

    # Optional: Image List ID for duplicate detection (create at dashboard.sightengine.com/image-lists)
    SIGHTENGINE_IMAGE_LIST_ID: ''

    # Optional: override default thresholds (0.0-1.0, lower = stricter)
    SIGHTENGINE_THRESHOLDS:
      nudity: 0.50
      weapon: 0.60
      violence: 0.50
      offensive: 0.50
      gore: 0.40
      self_harm: 0.50
      alcohol: 0.80
      drugs: 0.70
      tobacco: 0.80
      gambling: 0.80
      money: 0.90
      genai: 0.80
      quality: 0.15
      duplicate: 0.50

=cut

my $API_URL = 'https://api.sightengine.com/1.0/check.json';

my %DEFAULT_THRESHOLDS = (
    # Standard moderation
    nudity    => 0.50,  # Sexual/nude content
    weapon    => 0.60,  # Firearms, knives
    violence  => 0.50,  # Physical violence, threats
    offensive => 0.50,  # Hate signs, offensive gestures
    gore      => 0.40,  # Blood, corpses, wounds (strict)
    self_harm => 0.50,  # Self-harm content

    # Restricted content
    alcohol   => 0.80,  # Lenient - may appear in legitimate reports
    drugs     => 0.70,  # Recreational drugs
    tobacco   => 0.80,  # Smoking/tobacco
    gambling  => 0.80,  # Gambling scenes
    money     => 0.90,  # Very lenient - money rarely matters for reports

    # AI & quality
    genai     => 0.80,  # AI-generated images
    quality   => 0.15,  # Below this = too low quality (SightEngine returns 0-1 score)

    # Duplicate detection
    duplicate => 0.50,  # Similarity score threshold
);

sub is_enabled {
    return FixMyStreet->config('SIGHTENGINE_ENABLED') ? 1 : 0;
}

sub get_thresholds {
    my $custom = FixMyStreet->config('SIGHTENGINE_THRESHOLDS') || {};
    return { %DEFAULT_THRESHOLDS, %$custom };
}

=head2 moderate_photo($photo_blob)

Sends photo binary data to SightEngine for comprehensive moderation.

Returns:
  { allowed => 1 }                           -- photo is OK
  { allowed => 0, reason => "Description" }  -- photo rejected with detailed reason

=cut

sub moderate_photo {
    my ($photo_blob) = @_;

    return { allowed => 1 } unless is_enabled();

    my $api_user   = FixMyStreet->config('SIGHTENGINE_API_USER');
    my $api_secret = FixMyStreet->config('SIGHTENGINE_API_SECRET');

    unless ($api_user && $api_secret) {
        warn "SightEngine enabled but API credentials not configured\n";
        return { allowed => 1 };
    }

    my $result = try {
        my $ua = LWP::UserAgent->new(
            timeout => 20,
            agent   => 'InfraSignal/1.0',
        );

        # ALL visual moderation models
        my $models = join(',',
            'nudity-2.1',        # Nudity & suggestive
            'gore-2.0',          # Gore & disgusting
            'weapon',            # Weapons (firearms, knives)
            'violence',          # Physical violence
            'offensive-2.0',     # Hate & offensive signs
            'self-harm',         # Self-harm
            'recreational_drug', # Drugs
            'alcohol',           # Alcohol
            'tobacco',           # Smoking & tobacco
            'gambling',          # Gambling
            'money',             # Money & banknotes
            'text-content',      # OCR text moderation (profanity, PII, links)
            'genai',             # AI-generated image detection
            'quality',           # Image quality
        );

        # Build request content
        my @content = (
            api_user   => $api_user,
            api_secret => $api_secret,
            models     => $models,
            media      => [ undef, 'photo.jpg', Content_Type => 'image/jpeg', Content => $photo_blob ],
        );

        # Add duplicate detection list if configured
        my $list_id = FixMyStreet->config('SIGHTENGINE_IMAGE_LIST_ID');
        if ($list_id) {
            push @content, (
                lists       => $list_id,
                add_to_list => $list_id,  # Auto-add approved photos for future dedup
            );
        }

        my $response = $ua->post(
            $API_URL,
            Content_Type => 'form-data',
            Content      => \@content,
        );

        unless ($response->is_success) {
            warn "SightEngine API HTTP error: " . $response->status_line . "\n";
            return { allowed => 1 };
        }

        my $data = decode_json($response->content);

        if ($data->{status} && $data->{status} ne 'success') {
            warn "SightEngine API error: " . ($data->{error}{message} || 'unknown') . "\n";
            return { allowed => 1 };
        }

        return _evaluate_result($data);
    } catch {
        warn "SightEngine moderation error: $_\n";
        return { allowed => 1 };
    };

    return $result;
}

=head2 _evaluate_result($data)

Evaluates the SightEngine API response against configured thresholds.
Returns { allowed => 1 } or { allowed => 0, reason => "...", details => [...] }

=cut

sub _evaluate_result {
    my ($data) = @_;

    my $thresholds = get_thresholds();
    my @reasons;

    # ========== STANDARD MODERATION ==========

    # --- Nudity check (nudity-2.1 model) ---
    if (my $nudity = $data->{nudity}) {
        my $max_nudity = 0;
        my $nudity_type = '';
        for my $key (qw(sexual_activity sexual_display erotica very_suggestive suggestive)) {
            my $val = $nudity->{$key} || 0;
            if ($val > $max_nudity) {
                $max_nudity = $val;
                $nudity_type = $key;
            }
        }
        if ($max_nudity >= $thresholds->{nudity}) {
            (my $label = $nudity_type) =~ s/_/ /g;
            push @reasons, sprintf(_('Inappropriate content detected: %s (%d%% confidence)'), $label, $max_nudity * 100);
        }
    }

    # --- Weapon check ---
    if (my $weapon = $data->{weapon}) {
        my $score = 0;
        my $weapon_type = 'weapon';
        if (ref($weapon) eq 'HASH' && $weapon->{classes}) {
            for my $wtype (qw(firearm knife)) {
                my $val = $weapon->{classes}{$wtype} || 0;
                if ($val > $score) {
                    $score = $val;
                    $weapon_type = $wtype;
                }
            }
        } else {
            $score = ref($weapon) eq 'HASH' ? ($weapon->{prob} || 0) : $weapon;
        }
        if ($score >= $thresholds->{weapon}) {
            push @reasons, sprintf(_('Weapon detected: %s (%d%% confidence)'), $weapon_type, $score * 100);
        }
    }

    # --- Violence check ---
    if (my $violence = $data->{violence}) {
        my $score = ref($violence) eq 'HASH' ? ($violence->{prob} || 0) : $violence;
        if ($score >= $thresholds->{violence}) {
            push @reasons, sprintf(_('Violence detected (%d%% confidence)'), $score * 100);
        }
    }

    # --- Offensive / Hate check ---
    if (my $offensive = $data->{offensive}) {
        my $score = ref($offensive) eq 'HASH' ? ($offensive->{prob} || 0) : $offensive;
        if ($score >= $thresholds->{offensive}) {
            push @reasons, sprintf(_('Offensive/hate content detected (%d%% confidence)'), $score * 100);
        }
    }

    # --- Gore check ---
    if (my $gore = $data->{gore}) {
        my $score = ref($gore) eq 'HASH' ? ($gore->{prob} || 0) : $gore;
        if ($score >= $thresholds->{gore}) {
            push @reasons, sprintf(_('Graphic/gory content detected (%d%% confidence)'), $score * 100);
        }
    }

    # --- Self-harm check ---
    if (my $self_harm = $data->{'self-harm'}) {
        my $score = ref($self_harm) eq 'HASH' ? ($self_harm->{prob} || 0) : $self_harm;
        if ($score >= $thresholds->{self_harm}) {
            push @reasons, sprintf(_('Self-harm content detected (%d%% confidence)'), $score * 100);
        }
    }

    # ========== RESTRICTED CONTENT ==========

    # --- Alcohol check ---
    if (my $alcohol = $data->{alcohol}) {
        my $score = ref($alcohol) eq 'HASH' ? ($alcohol->{prob} || 0) : $alcohol;
        if ($score >= $thresholds->{alcohol}) {
            push @reasons, sprintf(_('Alcohol content detected (%d%% confidence)'), $score * 100);
        }
    }

    # --- Drugs check ---
    if (my $drugs = $data->{recreational_drug}) {
        my $score = ref($drugs) eq 'HASH' ? ($drugs->{prob} || 0) : $drugs;
        if ($score >= $thresholds->{drugs}) {
            push @reasons, sprintf(_('Drug-related content detected (%d%% confidence)'), $score * 100);
        }
    }

    # --- Tobacco check ---
    if (my $tobacco = $data->{tobacco}) {
        my $score = ref($tobacco) eq 'HASH' ? ($tobacco->{prob} || 0) : $tobacco;
        if ($score >= $thresholds->{tobacco}) {
            push @reasons, sprintf(_('Tobacco/smoking content detected (%d%% confidence)'), $score * 100);
        }
    }

    # --- Gambling check ---
    if (my $gambling = $data->{gambling}) {
        my $score = ref($gambling) eq 'HASH' ? ($gambling->{prob} || 0) : $gambling;
        if ($score >= $thresholds->{gambling}) {
            push @reasons, sprintf(_('Gambling content detected (%d%% confidence)'), $score * 100);
        }
    }

    # --- Money check ---
    if (my $money = $data->{money}) {
        my $score = ref($money) eq 'HASH' ? ($money->{prob} || 0) : $money;
        if ($score >= $thresholds->{money}) {
            push @reasons, sprintf(_('Money/banknote display detected (%d%% confidence)'), $score * 100);
        }
    }

    # ========== TEXT MODERATION IN IMAGES (OCR) ==========

    if (my $text = $data->{text}) {
        my @text_issues;

        # Profanity in image text
        if ($text->{profanity} && ref($text->{profanity}) eq 'ARRAY' && @{$text->{profanity}}) {
            my @matches = map { $_->{match} || $_->{type} || 'profanity' } @{$text->{profanity}};
            push @text_issues, _('profanity found: ') . join(', ', @matches);
        }

        # Personal info (emails, phone numbers, SSN, IP)
        if ($text->{personal} && ref($text->{personal}) eq 'ARRAY' && @{$text->{personal}}) {
            my @types = map { $_->{type} || 'personal info' } @{$text->{personal}};
            push @text_issues, _('personal information found: ') . join(', ', @types);
        }

        # Links/URLs
        if ($text->{link} && ref($text->{link}) eq 'ARRAY' && @{$text->{link}}) {
            push @text_issues, _('URL/link found in image');
        }

        # Social account references
        if ($text->{social} && ref($text->{social}) eq 'ARRAY' && @{$text->{social}}) {
            push @text_issues, _('social media account reference found');
        }

        # Extremism
        if ($text->{extremism} && ref($text->{extremism}) eq 'ARRAY' && @{$text->{extremism}}) {
            push @text_issues, _('extremist content found in text');
        }

        # Drug references in text
        if ($text->{drug} && ref($text->{drug}) eq 'ARRAY' && @{$text->{drug}}) {
            push @text_issues, _('drug reference found in text');
        }

        # Weapon references in text
        if ($text->{weapon} && ref($text->{weapon}) eq 'ARRAY' && @{$text->{weapon}}) {
            push @text_issues, _('weapon reference found in text');
        }

        # Violence in text
        if ($text->{violence} && ref($text->{violence}) eq 'ARRAY' && @{$text->{violence}}) {
            push @text_issues, _('violent language found in text');
        }

        # Self-harm in text
        if ($text->{'self-harm'} && ref($text->{'self-harm'}) eq 'ARRAY' && @{$text->{'self-harm'}}) {
            push @text_issues, _('self-harm references found in text');
        }

        # Spam / circumvention
        if ($text->{spam} && ref($text->{spam}) eq 'ARRAY' && @{$text->{spam}}) {
            push @text_issues, _('spam content found in text');
        }

        # Content trading
        if ($text->{'content-trade'} && ref($text->{'content-trade'}) eq 'ARRAY' && @{$text->{'content-trade'}}) {
            push @text_issues, _('content trading solicitation found');
        }

        # Money transaction solicitation
        if ($text->{'money-transaction'} && ref($text->{'money-transaction'}) eq 'ARRAY' && @{$text->{'money-transaction'}}) {
            push @text_issues, _('money transaction solicitation found');
        }

        if (@text_issues) {
            push @reasons, _('Text in image flagged: ') . join('; ', @text_issues);
        }
    }

    # ========== AI-GENERATED IMAGE DETECTION ==========

    if (my $genai = $data->{type}) {
        if (ref($genai) eq 'HASH' && defined $genai->{ai_generated}) {
            my $score = $genai->{ai_generated} || 0;
            if ($score >= $thresholds->{genai}) {
                push @reasons, sprintf(_('Image appears to be AI-generated (%d%% confidence)'), $score * 100);
            }
        }
    }

    # ========== IMAGE QUALITY ==========

    if (my $quality = $data->{quality}) {
        if (ref($quality) eq 'HASH' && defined $quality->{score}) {
            my $score = $quality->{score};
            if ($score < $thresholds->{quality}) {
                push @reasons, sprintf(_('Image quality too low (%d%% quality score, minimum %d%% required)'), $score * 100, $thresholds->{quality} * 100);
            }
        }
    }

    # ========== DUPLICATE / NEAR-DUPLICATE DETECTION ==========

    if (my $similarity = $data->{similarity}) {
        if (ref($similarity) eq 'ARRAY') {
            for my $list_result (@$similarity) {
                if ($list_result->{matches} && ref($list_result->{matches}) eq 'ARRAY' && @{$list_result->{matches}}) {
                    my $best_match = $list_result->{matches}[0];
                    my $score = $best_match->{score} || 0;
                    if ($score >= $thresholds->{duplicate}) {
                        push @reasons, sprintf(
                            _('Duplicate or near-duplicate image detected (%d%% similarity match)'),
                            $score * 100
                        );
                    }
                }
            }
        }
    }

    # ========== FINAL DECISION ==========

    if (@reasons) {
        return {
            allowed => 0,
            reason  => join('; ', @reasons),
            details => \@reasons,
        };
    }

    return { allowed => 1 };
}

=head2 moderate_text($text_string)

Sends text to SightEngine Text Moderation API for standalone text checking.
Use this for report descriptions, comments, etc.

Returns:
  { allowed => 1 }
  { allowed => 0, reason => "Description", details => [...] }

=cut

sub moderate_text {
    my ($text_string) = @_;

    return { allowed => 1 } unless is_enabled();
    return { allowed => 1 } unless $text_string && length($text_string) > 0;

    my $api_user   = FixMyStreet->config('SIGHTENGINE_API_USER');
    my $api_secret = FixMyStreet->config('SIGHTENGINE_API_SECRET');

    unless ($api_user && $api_secret) {
        return { allowed => 1 };
    }

    my $result = try {
        my $ua = LWP::UserAgent->new(
            timeout => 10,
            agent   => 'InfraSignal/1.0',
        );

        my $response = $ua->post(
            'https://api.sightengine.com/1.0/text/check.json',
            Content_Type => 'application/x-www-form-urlencoded',
            Content      => {
                text       => $text_string,
                lang       => 'en',
                mode       => 'ml,rules',  # Both ML classification + rule-based
                api_user   => $api_user,
                api_secret => $api_secret,
            },
        );

        unless ($response->is_success) {
            warn "SightEngine Text API HTTP error: " . $response->status_line . "\n";
            return { allowed => 1 };
        }

        my $data = decode_json($response->content);

        if ($data->{status} && $data->{status} ne 'success') {
            warn "SightEngine Text API error: " . ($data->{error}{message} || 'unknown') . "\n";
            return { allowed => 1 };
        }

        return _evaluate_text_result($data);
    } catch {
        warn "SightEngine text moderation error: $_\n";
        return { allowed => 1 };
    };

    return $result;
}

=head2 _evaluate_text_result($data)

Evaluates SightEngine Text Moderation API response.

=cut

sub _evaluate_text_result {
    my ($data) = @_;

    my @reasons;

    # ML classification results
    if (my $classes = $data->{moderation_classes}) {
        for my $class (qw(sexual discriminatory insulting violent toxic self-harm)) {
            if (defined $classes->{$class} && $classes->{$class} > 0.70) {
                (my $label = $class) =~ s/-/ /g;
                push @reasons, sprintf(_('Text flagged as %s (%d%% confidence)'), $label, $classes->{$class} * 100);
            }
        }
    }

    # Rule-based results
    if (my $profanity = $data->{profanity}) {
        if (ref($profanity) eq 'HASH' && $profanity->{matches} && @{$profanity->{matches}}) {
            my @matches = map { $_->{match} || 'profanity' } @{$profanity->{matches}};
            push @reasons, _('Profanity detected in text: ') . join(', ', @matches);
        }
    }

    if (my $personal = $data->{personal}) {
        if (ref($personal) eq 'HASH' && $personal->{matches} && @{$personal->{matches}}) {
            my @types = map { $_->{type} || 'personal info' } @{$personal->{matches}};
            push @reasons, _('Personal information in text: ') . join(', ', @types);
        }
    }

    if (my $link = $data->{link}) {
        if (ref($link) eq 'HASH' && $link->{matches} && @{$link->{matches}}) {
            push @reasons, _('URL/link found in text');
        }
    }

    if (@reasons) {
        return {
            allowed => 0,
            reason  => join('; ', @reasons),
            details => \@reasons,
        };
    }

    return { allowed => 1 };
}

1;
