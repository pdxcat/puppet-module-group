# Custom group providers for Puppet

## Description
At Portland State University we had a need for managing local group membership
on Ubuntu, FreeBSD and Solaris, but we don't manage local users. That is, we
needed group providers with feature manages_members. The default group
providers in puppet weren't set up for this so we wrote some custom stuff. This
is it.
