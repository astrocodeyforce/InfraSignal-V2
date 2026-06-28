package FixMyStreet::App::Controller::Auth::Profile;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use mySociety::AuthToken;

=head1 NAME

FixMyStreet::App::Controller::Auth::Profile - Catalyst Controller

=head1 DESCRIPTION

Controller for all the authentication profile related pages - adding/ changing/
verifying email, phone, password.

=head1 METHODS

=cut

use constant CLOSE_ACCOUNT_PHRASE => 'DELETE';

# Undo-able grace period before a confirmed closure is actually anonymized.
# Kept in sync with bin/process-account-closures (the purge job).
use constant CLOSURE_GRACE_DAYS => 30;

sub auto : Private {
    my ( $self, $c ) = @_;

    # The emailed account-closure confirmation link must keep working even if
    # the login session has since expired, so it authenticates via the one-time
    # token rather than the session.
    return 1 if $c->action->name eq 'close_account_confirm';

    $c->detach( '/auth/redirect' ) unless $c->user;

    return 1;
}

sub change_name : Path('/auth/change_name') {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'auth/change_name.html';

    $c->forward('/auth/get_csrf_token');

    # If not a post then no submission
    return unless $c->req->method eq 'POST';

    $c->forward('/auth/check_csrf_token');

    my $name = $c->get_param('name') // '';
    $name =~ s/^\s+//;
    $name =~ s/\s+$//;
    $c->stash->{profile_name} = $name;

    if (!$name) {
        $c->stash->{name_error} = 'missing';
        return;
    }

    if (length $name > 100) {
        $c->stash->{name_error} = 'too_long';
        return;
    }

    $c->user->update({ name => $name });
    $c->flash->{flash_message} = _('You have successfully updated your name.');
    $c->res->redirect('/my');
    $c->detach;
}

=head2 change_password

Let the user change their password.

=cut

sub change_password : Path('/auth/change_password') {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'auth/change_password.html';

    $c->forward('/auth/get_csrf_token');

    # If not a post then no submission
    return unless $c->req->method eq 'POST';

    $c->forward('/auth/check_csrf_token');

    # get the passwords
    my $new = $c->get_param('new_password') // '';
    my $confirm = $c->get_param('confirm') // '';

    my $password_error;

    # Check existing password, if available
    if ($c->user->password) {
        my $current = $c->get_param('current_password') // '';
        $c->stash->{current_password} = $current;
        $password_error = 'incorrect' unless $c->user->check_password($current);
    }

    # check for errors
    $password_error ||=
       !$new && !$confirm ? 'missing'
      : $new ne $confirm ? 'mismatch'
      : !$c->forward('/auth/test_password', [ $new ]) ? 'failed'
      :                    '';

    if ($password_error) {
        $c->stash->{password_error} = $password_error;
        $c->stash->{new_password}   = $new;
        $c->stash->{confirm}        = $confirm;
        return;
    }

    if ($c->user->password) {
        # we should have a usable password - save it to the user
        $c->user->obj->password($new);
        $c->user->obj->update;
        $c->stash->{password_changed} = 1;
    } else {
        # Set up arguments for code sign in
        $c->set_param('username', $c->user->username);
        $c->set_param('password_register', $new);
        $c->set_param('r', 'auth/change_password/success');
        $c->detach('/auth/code_sign_in');
    }
}

=head2 change_email

Let the user change their email.

=cut

sub change_email : Path('/auth/change_email') {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'auth/change_email.html';

    $c->forward('/auth/get_csrf_token');

    # If not a post then no submission
    return unless $c->req->method eq 'POST';

    $c->forward('/auth/check_csrf_token');
    $c->stash->{current_user} = $c->user;
    $c->stash->{email_template} = 'change_email.txt';
    $c->forward('/auth/email_sign_in', [ $c->get_param('email') ]);
}

sub change_phone : Path('/auth/change_phone') {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'auth/change_phone.html';

    $c->forward('/auth/get_csrf_token');

    # If not a post then no submission
    return unless $c->req->method eq 'POST';

    $c->forward('/auth/check_csrf_token');
    $c->stash->{current_user} = $c->user;

    my $phone = $c->stash->{username} = $c->get_param('username') || '';
    my $parsed = FixMyStreet::SMS->parse_username($phone);

    # Allow removal of phone number, if we have verified email
    if (!$phone && !$c->stash->{verifying} && $c->user->email_verified) {
        $c->user->update({ phone => undef, phone_verified => 0 });
        $c->flash->{flash_message} = _('You have successfully removed your phone number.');
        $c->res->redirect('/my');
        $c->detach;
    }

    $c->stash->{username_error} = 'missing_phone', return unless $phone;
    $c->stash->{username_error} = 'other_phone', return unless $parsed->{phone};

    # If we've not used a mobile and we're not specifically verifying,
    # and phone isn't our only verified way of logging in,
    # then allow change of number (for e.g. landline).
    if (!$c->cobrand->sms_authentication || (!$parsed->{may_be_mobile} && !$c->stash->{verifying} && $c->user->email_verified)) {
        $c->user->update({ phone => $phone, phone_verified => 0 });
        $c->flash->{flash_message} = _('You have successfully added your phone number.');
        $c->res->redirect('/my');
        $c->detach;
    }

    $c->forward('/auth/phone/sign_in', [ $parsed ]);
}

sub verify_item : Path('/auth/verify') : Args(1) {
    my ( $self, $c, $type ) = @_;
    $c->stash->{verifying} = 1;
    $c->detach("change_$type");
}

sub change_email_success : Path('/auth/change_email/success') {
    my ( $self, $c ) = @_;
    $c->flash->{flash_message} = _('You have successfully confirmed your email address.');
    $c->res->redirect('/my');
}

sub change_phone_success : Path('/auth/change_phone/success') {
    my ( $self, $c ) = @_;
    $c->flash->{flash_message} = _('You have successfully verified your phone number.');
    $c->res->redirect('/my');
}

sub change_password_success : Path('/auth/change_password/success') {
    my ( $self, $c ) = @_;
    $c->flash->{flash_message} = _('Your password has been changed');
    $c->res->redirect('/my');
}

=head2 close_account

Self-service account closure, step 1. Shows a warning screen and, on a valid
POST (typed confirmation phrase + current password where the account has one),
emails a one-time confirmation link. Nothing is changed until that link is
followed, so an accidental or malicious request cannot remove an account.

=cut

sub close_account : Path('/auth/close_account') {
    my ( $self, $c ) = @_;

    $c->stash->{template}       = 'auth/close_account.html';
    $c->stash->{confirm_phrase} = CLOSE_ACCOUNT_PHRASE;
    $c->stash->{has_password}   = $c->user->password ? 1 : 0;
    $c->stash->{grace_days}     = CLOSURE_GRACE_DAYS;

    $c->forward('/auth/get_csrf_token');

    return unless $c->req->method eq 'POST';

    $c->forward('/auth/check_csrf_token');

    # Platform superusers cannot self-close (avoids accidentally removing the
    # only admin); they must be handled by another superuser via /admin.
    if ( $c->user->is_superuser ) {
        $c->stash->{close_error} = 'superuser';
        return;
    }

    # Typed confirmation phrase (case-insensitive).
    my $typed = $c->get_param('confirm_phrase') // '';
    $typed =~ s/^\s+//;
    $typed =~ s/\s+$//;
    unless ( uc($typed) eq CLOSE_ACCOUNT_PHRASE ) {
        $c->stash->{close_error} = 'phrase';
        return;
    }

    # Current password, when the account has one set.
    if ( $c->user->password ) {
        my $current = $c->get_param('current_password') // '';
        unless ( length $current && $c->user->check_password($current) ) {
            $c->stash->{close_error} = 'password';
            return;
        }
    }

    # One-time token carrying the user id; get_token enforces a 1-day lifetime.
    my $token_obj = $c->model('DB::Token')->create({
        scope => 'close_account',
        data  => { user_id => $c->user->id },
    });

    $c->stash->{token} = $token_obj->token;
    $c->send_email( 'close_account.txt', { to => $c->user->email } );
    $c->stash->{email_sent} = 1;
}

=head2 close_account_confirm

Self-service account closure, step 2. Validates the emailed one-time token and
*schedules* the account for closure after a grace period (CLOSURE_GRACE_DAYS),
rather than anonymizing immediately. This lets the user undo an accidental or
malicious (account-takeover) request by signing back in and cancelling. The
actual anonymization is performed by bin/process-account-closures once the grace
period elapses. The user is signed out here.

=cut

sub close_account_confirm : Path('/auth/close_account/confirm') : Args(1) {
    my ( $self, $c, $token ) = @_;

    $c->stash->{template} = 'auth/close_account_done.html';

    my $data = $c->forward( '/auth/get_token', [ $token, 'close_account' ] );
    return if $c->stash->{token_not_found};

    my $user = $c->model('DB::User')->find({ id => $data->{user_id} });
    $c->stash->{token_not_found} = 1, return unless $user;

    # Already anonymized (e.g. by an admin) — nothing to schedule.
    unless ( $user->email && $user->email =~ /^removed-\d+\@/ ) {
        my $now = time();
        $user->set_extra_metadata( closure_requested_at => $now );
        $user->set_extra_metadata( closure_method       => 'self' );
        $user->update;
        $c->stash->{closure_date} = $now + CLOSURE_GRACE_DAYS * 24 * 60 * 60;
    }

    # Burn the token so the link cannot be reused.
    $c->model('DB::Token')
        ->search({ scope => 'close_account', token => $token })->delete;

    # End the active session if it belongs to this account; the user can sign
    # back in during the grace period to cancel.
    $c->logout() if $c->user_exists && $c->user->id == $data->{user_id};

    $c->stash->{grace_days}        = CLOSURE_GRACE_DAYS;
    $c->stash->{closure_scheduled} = 1;
}

=head2 cancel_close_account

Lets a signed-in user cancel a pending account closure during the grace period
("Keep my account").

=cut

sub cancel_close_account : Path('/auth/close_account/cancel') {
    my ( $self, $c ) = @_;

    $c->forward('/auth/get_csrf_token');

    if ( $c->req->method eq 'POST' ) {
        $c->forward('/auth/check_csrf_token');
        $c->user->unset_extra_metadata('closure_requested_at');
        $c->user->unset_extra_metadata('closure_method');
        $c->user->update;
        $c->flash->{flash_message} = _('Your account closure has been cancelled — welcome back.');
    }

    $c->res->redirect('/my');
    $c->detach;
}

sub generate_token : Path('/auth/generate_token') {
    my ($self, $c) = @_;

    $c->detach( '/page_error_403_access_denied', [] )
        unless $c->user and ( $c->user->is_superuser or $c->user->from_body );

    $c->stash->{template} = 'auth/generate_token.html';
    $c->forward('/auth/get_csrf_token');

    my $has_2fa = $c->user->get_extra_metadata('2fa_secret');

    if ($c->req->method eq 'POST') {
        $c->forward('/auth/check_csrf_token');

        if ($c->get_param('generate_token')) {
            my $token = mySociety::AuthToken::random_token();
            my $u = FixMyStreet::DB->resultset("User")->new({ password => $token });
            $c->user->set_extra_metadata('access_token', $u->password);
            $c->user->update;
            $c->stash->{token_generated} = $c->user->id . '-' . $token;
        }

        my $action = $c->get_param('2fa_action') || '';
        $action = 'deactivate' if $c->get_param('2fa_deactivate');
        $action = 'activate' if $c->get_param('2fa_activate');
        $action = 'activate' if $action eq 'deactivate' && $has_2fa && $c->cobrand->call_hook('must_have_2fa', $c->user);

        my $secret;
        if ($action eq 'deactivate') {
            $c->user->unset_extra_metadata('2fa_secret');
            $c->user->update;
            $c->stash->{toggle_2fa_off} = 1;
        } elsif ($action eq 'confirm') {
            $secret = $c->get_param('secret32');
            if ($c->check_2fa($secret)) {
                $c->user->set_extra_metadata('2fa_secret', $secret);
                $c->user->update;
                $c->stash->{stage} = 'success';
                $has_2fa = 1;
            } else {
                $action = 'activate'; # Incorrect code, reshow
            }
        }

        if ($action eq 'activate') {
            my $auth = FixMyStreet::Auth::GoogleAuth->new;
            $c->stash->{qr_code} = $auth->qr_code($secret, $c->user->email, $c->cobrand->base_url);
            $c->stash->{secret32} = $auth->secret32;
            $c->stash->{stage} = 'activate';
        }
    }

    $c->stash->{has_2fa} = $has_2fa ? 1 : 0;
    $c->stash->{existing_token} = $c->user->get_extra_metadata('access_token') ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;

1;
