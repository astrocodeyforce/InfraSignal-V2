package Catalyst::Plugin::FixMyStreet::Session::RotateSession;
use Moose::Role;
use namespace::autoclean;

# After successful authentication, rotate the session ID
after set_authenticated => sub {
    my $c = shift;
    $c->change_session_id;

    # Stamp the login moment so Root::auto can enforce idle + absolute session
    # timeouts on authenticated users (see check_session_timeout). set_authenticated
    # only fires on a real login (not on session restore), so this marks the true
    # start of the session for the absolute-lifetime cap.
    my $now = time();
    $c->session->{auth_login_time}  = $now;
    $c->session->{auth_last_active} = $now;
};

# The below is necessary otherwise the rotation fails due to the delegate
# holding on to the now-deleted old session. See
# https://rt.cpan.org/Public/Bug/Display.html?id=112679

after delete_session_data => sub {
    my ($c, $key) = @_;

    my ($field) = split(':', $key);
    if ($field eq 'session') {
        $c->_session_store_delegate->_session_row(undef);
    } elsif ($field eq 'flash') {
        $c->_session_store_delegate->_flash_row(undef);
    }
};

1;
