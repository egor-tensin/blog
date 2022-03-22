---
title: 'Docker: bind mounts & file ownership'
excerpt: Docker + bind mounts + non-root users = pain.
---
If you want to:

1. run your Docker service as a user other than root,
2. share a writable directory between your host and the container,

you're in for a treat!
The thing is, files stored in the shared directory retain their ownership (and
by that I mean their UIDs and GIDs, as they're the only thing that matters)
after being mounted in the container.

Case in point:

{% capture cmd1 %}
docker run -it --rm -v "$( pwd ):/data" alpine touch /data/test.txt
{% endcapture %}

{% include shell.html cmd=cmd1 %}

would create file ./test.txt owned by root:root.

You can fix that by using the `--user` parameter:

{% capture cmd1 %}
docker run -it --rm -v "$( pwd ):/data" --user "$( id -u ):$( id -g )" alpine touch /data/test.txt
{% endcapture %}

{% include shell.html cmd=cmd1 %}

That would create file ./test.txt owned by the current user (if the current
working directory is writable by the current user, of course).

More often though, instead of a simple `touch` call, you have a 24/7 service,
which absolutely mustn't run as root, regardless of whether `--user` was
specified or not.
In such cases, the logical solution would be to create a regular user in the
container, and use it to run the service.
In fact, that's what many popular images do, i.e. [Redis][Redis Dockerfile] and
[MongoDB][MongoDB Dockerfile].

[Redis Dockerfile]: https://github.com/docker-library/redis/blob/cc1b618d51eb5f6bf6e3a03c7842317b38dbd7f9/6.0/Dockerfile#L4
[MongoDB Dockerfile]: https://github.com/docker-library/mongo/blob/5cbf7be9a486932b7e472a39e432c9a444628465/4.2/Dockerfile#L4

How do you run the service as regular user though?
It's tempting to use the `USER` directive in the Dockerfile, but that can be
overridden by `--user`:

{% capture cmd1 %}
cat Dockerfile
{% endcapture %}
{% capture out1 %}
FROM alpine

RUN addgroup --gid 9099 test-group && \
    adduser \
        --disabled-password \
        --gecos '' \
        --home /home/test-user \
        --ingroup test-group \
        --uid 9099 \
        test-user

RUN touch /root.txt
USER test-user:test-group
RUN touch /home/test-user/test-user.txt

CMD id && stat -c '%U %G' /root.txt && stat -c '%U %G' /home/test-user/test-user.txt
{% endcapture %}

{% capture cmd2 %}
docker build -t id .
{% endcapture %}

{% capture cmd3 %}
docker run -it --rm id
{% endcapture %}
{% capture out3 %}
uid=9099(test-user) gid=9099(test-group)
root root
test-user test-group
{% endcapture %}

{% capture cmd4 %}
docker run -it --rm --user root id
{% endcapture %}
{% capture out4 %}
uid=0(root) gid=0(root) groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),11(floppy),20(dialout),26(tape),27(video)
root root
test-user test-group
{% endcapture %}

{% include shell.html cmd=cmd1 out=out1 %}
{% include shell.html cmd=cmd2 %}
{% include shell.html cmd=cmd3 out=out3 %}
{% include shell.html cmd=cmd4 out=out4 %}

I suppose that's the reason why many popular images override ENTRYPOINT, using
a custom script (and `gosu`, which is basically `sudo`, I think) to forcefully
drop privileges (for example, see [Redis][Redis entrypoint],
[MongoDB][MongoDB entrypoint]).

[Redis entrypoint]: https://github.com/docker-library/redis/blob/cc1b618d51eb5f6bf6e3a03c7842317b38dbd7f9/6.0/docker-entrypoint.sh#L11
[MongoDB entrypoint]: https://github.com/docker-library/mongo/blob/5cbf7be9a486932b7e472a39e432c9a444628465/4.2/docker-entrypoint.sh#L12

Now, what if such service needs persistent storage?
A good solution would be to use Docker volumes.
For development though, you often need to just share a directory between your
host and the container, and it has to be writable by both the host and the
container process.
This can be accomplished using _bind mounts_.
For example, let's try to map ./data to /data inside a Redis container (this
assumes ./data doesn't exist and you're running as regular user with UID 1000;
press Ctrl+C to stop Redis):

{% capture cmd1 %}
mkdir data
{% endcapture %}

{% capture cmd2 %}
stat -c '%u' data
{% endcapture %}
{% capture out2 %}
1000
{% endcapture %}

{% capture cmd3 %}
docker run -it --rm --name redis -v "$( pwd )/data:/data" redis:6.0
{% endcapture %}

{% capture cmd4 %}
stat -c '%u' data
{% endcapture %}
{% capture out4 %}
999
{% endcapture %}

{% include shell.html cmd=cmd1 %}
{% include shell.html cmd=cmd2 out=out2 %}
{% include shell.html cmd=cmd3 %}
{% include shell.html cmd=cmd4 out=out4 %}

As you can see, ./data changed its owner from user with UID 1000 (the host
user) to user with UID 999 (the `redis` user inside the container).
This is done in Redis' ENTRYPOINT script, just before dropping root privileges
so that the `redis-server` process owns the /data directory and thus can write
to it.

If you want to preserve ./data ownership, Redis' image (and many others)
explicitly accommodates for it by _not_ changing its owner if the container is
run as anybody other than root.
For example:

{% capture cmd1 %}
mkdir data
{% endcapture %}

{% capture cmd2 %}
stat -c '%u' data
{% endcapture %}
{% capture out2 %}
1000
{% endcapture %}

{% capture cmd3 %}
docker run -it --rm --name redis -v "$( pwd )/data:/data" --user "$( id -u ):$( id -g )" redis:6.0
{% endcapture %}

{% capture cmd4 %}
stat -c '%u' data
{% endcapture %}
{% capture out4 %}
1000
{% endcapture %}

{% include shell.html cmd=cmd1 %}
{% include shell.html cmd=cmd2 out=out2 %}
{% include shell.html cmd=cmd3 %}
{% include shell.html cmd=cmd4 out=out4 %}

Sometimes `--user` is not enough though.
That specified user is almost certainly missing from container's /etc/passwd,
it doesn't have a $HOME, etc.
All of that could cause problems with some applications.

One scenario I had to deal with is making an image that bundles all the gems
(and a specific Ruby version) for my Ruby web application.
That application shouldn't be run as root, but it must be able to pick up code
changes on the fly, and I should be able to `docker exec` into the container,
update the dependencies (along with Gemfile[.lock], and those changes should be
reflected on the host without messing up file metadata), and restart the app.
It's quite easy to install the dependencies in the Dockerfile, but they (along
with the mapped Gemfile[.lock]) should be writable by the user running the
service.
The solution often suggested is to create a container user with a fixed UID
(that would match the host user UID).
That way, it would be able to update the dependencies stored in the container,
as well as write to the bind mount owned by the host user with the same UID.
Additionally, file ownership info would be preserved on the host!

We can create a user with a fixed UID when

1. building the image (using build `ARG`uments),
2. first starting the container by passing the required UID using environment
variables.

The advantages of creating the user when building the image is that we can also
install the dependencies in the Dockerfile, thus eliminating the need to
rebuild them for every other application.
The disadvantage is that the image would need to be rebuilt for every user on
every machine.

Creating the user when first starting the container has the advantage of not
requiring image rebuilds.
But, as the dependencies need to be installed after creating the user, you'd
have to waste resources by installing them for every user and every app on
every machine (each time when creating a container).

For my project [jekyll-docker] I opted for the former approach, making sure the
`jekyll` process runs with the same UID as the user who built the image (unless
it was built by root, in which case it falls back to a custom UID of 999).
Seems to work quite nicely in practice.

[jekyll-docker]: https://github.com/egor-tensin/jekyll-docker/tree/7d1824a5fac0ed483bc49209bbd89f564a7bcefe

Useful links
------------

* [Docker and \-\-userns-remap, how to manage volume permissions to share data between host and container?](https://stackoverflow.com/q/35291520/514684)
* [What is the (best) way to manage permissions for Docker shared volumes?](https://stackoverflow.com/q/23544282/514684)
* [Handling Permissions with Docker Volumes](https://denibertovic.com/posts/handling-permissions-with-docker-volumes/)
* [File Permissions: the painful side of Docker](https://blog.gougousis.net/file-permissions-the-painful-side-of-docker/)
* [Avoiding Permission Issues With Docker-Created Files](https://vsupalov.com/docker-shared-permissions/)
