---
title: Persistent SSH tunnel
excerpt: ... using Cygwin.
---
SSH tunneling is awesome.
For some reason, I've only recently learned about this feature, but I've been
immediately blown away by how useful it can be.

Basically, to use SSH tunneling (a.k.a. port forwarding) you need to have a SSH
client (`ssh`) with an access to a SSH server.
You can then access any port on any host your SSH server has access to.
It works like this:

* your SSH client establishes a connection to the SSH server,
* the client asks the server to forward incoming requests to the destination
host,
* the client listens to the proxy port on the local machine, and forwards
requests to the SSH server.

Say, you have access to SSH server `gateway` on port 22, and you want to gain
access to HTTPS server `dest` on port 443, which is only accessible from the
network both it and the SSH server belong to.
You can then run something like

{% include jekyll-theme/shell.html cmd='ssh -L 4433:dest:443 gateway -p 22' %}

And now you can access `dest` at `https://localhost:4433/`.
That's brilliant, really.

But there's more.
You can make a _reverse_ tunnel, allowing you to give access to any host your
client computer has access to, via a remote SSH server.
It works like this:

* your SSH client establishes a connection with the SSH server,
* the client asks the server to listen to a port of your choosing and forward
incoming requests to the client,
* the client forwards incoming requests to the destination host.

This, as I've recently learned, is a common pattern to subvert corporate
firewalls, which frequently forbid incoming connections.
Say, you want to access your work computer from home via RDP.
Both your home and your work computers have access to a SSH server `gateway` on
port 22 (you might want to change it to port 80 or 443 if your outside
connections are filtered).

You can then run something like (notice the `-R`)

{% include jekyll-theme/shell.html cmd='ssh -R 13389:127.0.0.1:3389 gateway -p 22' %}

and now you can connect to `gateway:13389` from your home computer using a RDP
client.
Even more brilliant!

You might need to set the `GatewayPorts` setting to `yes` or `clientspecified`
on your SSH server (typically in "/etc/ssh/sshd_config").

Batch mode
----------

If you want to establish a reverse SSH tunnel automatically, some tweaking is
required.
First, set some SSH client options:

* `-F /dev/null` to disregard the user config,
* `-oBatchMode=yes` to run non-interactively,
* `-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null` to disable server
verification (optional),
* `-oExitOnForwardFailure=yes` to exit if port forwarding fails,
* `-oServerAliveCountMax=3 -oServerAliveInterval=15` to break the connection if
the server or the network is down,
* `-N -n -T` to only forward the ports and not execute the shell or any
additional commands.

Thus, the full command would be something like

{% capture cmd1 %}
ssh                                \
    -F /dev/null                   \
    -oBatchMode=yes                \
    -oStrictHostKeyChecking=no     \
    -oUserKnownHostsFile=/dev/null \
    -oExitOnForwardFailure=yes     \
    -oServerAliveCountMax=3        \
    -oServerAliveInterval=15       \
    -N -n -T                       \
    -R 13389:127.0.0.1:3389        \
    user@gateway -p 22             \
    -i ~/.ssh/tunnel
{% endcapture %}

{% include jekyll-theme/shell.html cmd=cmd1 %}

Adjust the `user@gateway -p 22` part accordingly.

Notice also `-i ~/.ssh/tunnel`.
It's the path to the SSH key used to authenticate with the server.
It can't have a passphrase, since the command will be run non-interactively,
and the public key must be in the server's authorized_keys file.

For best results, you should also adjust some settings on the SSH server.
Namely, you should enable client keep-alives on the server using something like

```
ClientAliveCountMax 3
ClientAliveInterval 15
```

Unless you do that, even if the client breaks the connection, you won't be able
to re-establish it for a long-ish time, since the server wouldn't know that the
original connection is no longer valid.

As a service
------------

Cygwin is awesome.
I've been using for 10+ years, and it has never failed me.
It comes with a SSH server, a client (you need to install the `openssh` package
for both of these), and a service manager, `cygrunsrv`.
`cygrunsrv` is similar to [NSSM], as it allows to wrap any executable into a
native Windows service.

[NSSM]: https://nssm.cc/

Using `cygrunsrv`, you can create a Windows service to establish a reverse SSH
tunnel automatically.

{% capture cmd1 %}
cygrunsrv                        \
    -I ssh_tunnel                \
    -p /usr/bin/ssh              \
    --args '-F /dev/null -oBatchMode=yes -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oExitOnForwardFailure=yes -oServerAliveCountMax=3 -oServerAliveInterval=15 -N -n -T -R 13389:127.0.0.1:3389 user@gateway -p 22 -i ~/.ssh/tunnel' \
    --disp 'Reverse SSH tunnels' \
    --user user                  \
    --neverexits                 \
    --preshutdown
{% endcapture %}

{% include jekyll-theme/shell.html cmd=cmd1 %}

Adjust the `--user` and the `--args` values accordingly.

You can then run `services.msc` and adjust the recovery settings for the
service to restart if `ssh` fails:

<div class="row">
  <div class="col-xs-12 col-sm-8 col-md-6">
    <a href="{{ '/assets/img/ssh_tunnel_services.png' | relative_url }}" class="thumbnail">
      <img class="img-responsive" alt="services.msc" src="{{ '/assets/img/ssh_tunnel_services.png' | relative_url }}">
    </a>
  </div>
</div>

And voilà, you have an automatic reverse SSH tunnel on Windows for you!
