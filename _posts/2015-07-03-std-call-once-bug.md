---
title: std::call_once bug in Visual C++ 2012/2013
excerpt: >
  In this post I will describe a nasty bug I've stumbled upon in the C++
  Standard Library implementation shipped with Microsoft Visual Studio
  2012/2013.
category: C++
---
I've recently come across a nasty standard library bug in the implementation
shipped with Microsoft Visual Studio 2012/2013.
[StackOverflow was of no help], so I had to somehow report the bug to the
maintainers.
Oddly enough, Visual Studio's [Connect page] wouldn't let me report one,
complaining about the lack of permissions, even though I was logged in from my
work account, associated with my Visual Studio 2013 installation.

Fortunately, I've come across the personal website of this amazing guy,
[Stephan T. Lavavej], who appears to be the chief maintainer of Microsoft's
standard library implementation.
He seems to be your go-to guy when it comes to obvious standard library
misbehaviours.

[StackOverflow was of no help]: https://stackoverflow.com/questions/26477070/concurrent-stdcall-once-calls
[Connect page]: https://connect.microsoft.com/VisualStudio
[Stephan T. Lavavej]: http://nuwen.net/stl.html

C++11 and singletons
--------------------

Anyway, the story begins with me trying to implement the singleton pattern
using C++11 facilities like this:

```c++
#include <mutex>

template <typename Derived>
class Singleton {
public:
    static Derived& get_instance() {
        std::call_once(initialized_flag, &initialize_instance);
        return Derived::get_instance_unsafe();
    }

protected:
    Singleton() = default;
    ~Singleton() = default;

    static Derived& get_instance_unsafe() {
        static Derived instance;
        return instance;
    }

private:
    static void initialize_instance() {
        Derived::get_instance_unsafe();
    }

    static std::once_flag initialized_flag;

    Singleton(const Singleton&) = delete;
    Singleton& operator=(const Singleton&) = delete;
};

template <typename Derived>
std::once_flag Singleton<Derived>::initialized_flag;
```

Neat, huh?
Now other classes can inherit from `Singleton`, implementing the singleton
pattern effortlessly:

```c++
class Logger : public Singleton<Logger> {
private:
    Logger() = default;
    ~Logger() = default;

    friend class Singleton<Logger>;
};
```

Note that the [N2660] standard proposal isn't/wasn't implemented in the
compilers shipped with Visual Studio 2012/2013.
If it was, I wouldn't, of course, need to employ this `std::call_once`
trickery, and the implementation would be much simpler, i.e. something like
this:

```c++
class Logger {
public:
    static Logger& get_instance() {
        static Logger instance;
        return instance;
    }

private:
    Logger() = default;
    ~Logger() = default;
};
```

<div class="alert alert-info" markdown="1">

The point is that the `Logger::get_instance` routine above wasn't thread-safe
until C++11.
Imagine what might happen if `Logger`'s constructor takes some time to
initialize the instance.
If a couple of threads then call `get_instance`, the first thread might begin
the initialization process, making the other thread believe that the instance
had already been intialized.
This other thread might then return a reference to the instance which hasn't
yet completed its initialization and is most likely unsafe to use.
    
Since C++11 includes the proposal mentioned above, this routine would indeed be
thread-safe in C++11.
Unfortunately, the compilers shipped with Visual Studio 2012/2013 don't/didn't
implement this particular proposal, which caused me to look at
`std::call_once`, which seemed to implement exactly what I needed.

</div>

[N2660]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2008/n2660.htm

Problem
-------

Unfortunately, matters became a bit more complicated when I tried to introduce
two singletons, one having a dependency on the other.
I had `Logger`, like in the example above, and some kind of a "master"
singleton (let's call it `Duke`).
`Duke`'s constructor was complicated and time-consuming, and definetely
required some logging to be done.
I thought that I could simply call `Logger::get_instance` inside `Duke`'s
constructor, and everything looked fine at first glance.

```c++
#include <chrono>
#include <thread>

class Logger : public Singleton<Logger> {
public:
    Logger& operator<<(const char* msg) {
        // Actual logging is stripped for brevity.
        return *this;
    }

private:
    Logger() {
        // Opening log files, etc.
        std::this_thread::sleep_for(std::chrono::seconds{3});
    }

    ~Logger() = default;

    friend class Singleton<Logger>;
};

class Duke : public Singleton<Duke> {
private:
    Duke() {
        Logger::get_instance() << "started Duke's initialization";
        // It's a lot of work to be done.
        std::this_thread::sleep_for(std::chrono::seconds{10});
        Logger::get_instance() << "finishing Duke's initialization";
    }

    ~Duke() = default;

    friend class Singleton<Duke>;
};
```

Now, what happens if I have two threads, one using the `Duke` instance, and the
other logging something?
Like in this example:

```c++
#include <thread>

namespace {

void get_logger() {
    entered(__FUNCTION__);
    Logger::get_instance();
    exiting(__FUNCTION__);
}

void get_duke() {
    entered(__FUNCTION__);
    Duke::get_instance();
    exiting(__FUNCTION__);
}

}

int main() {
    std::thread t1{&get_duke};
    std::thread t2{&get_logger};
    t1.join();
    t2.join();
    return 0;
}
```

`entered` and `exiting` are utility functions to print timestamps.
The implementation is included in the [complete code sample].
{: .alert .alert-info }

The first thread is supposed to have the total running time of about 13
seconds, right?
Three seconds to initialize the `Logger` instance and ten to initialize the
`Duke` instance.
The second thread, similarly, is supposed to be done in about 3 seconds
required for the initialization of `Logger`.

Weirdly, this program produces the following output when compiled using Visual
Studio 2013's compiler:

    Entered `anonymous-namespace'::get_duke at Fri Jul 03 02:26:16 2015
    Entered `anonymous-namespace'::get_logger at Fri Jul 03 02:26:16 2015
    Exiting `anonymous-namespace'::get_duke at Fri Jul 03 02:26:29 2015
    Exiting `anonymous-namespace'::get_logger at Fri Jul 03 02:26:29 2015

Isn't it wrong that the second thread actually took the same 13 seconds as the
first thread?
Better check with some other compiler in case it was me who made a mistake.
Unfortunately, the program behaves as expected when compiled using GCC:

    Entered get_logger at Fri Jul  3 02:27:12 2015
    Entered get_duke at Fri Jul  3 02:27:12 2015
    Exiting get_logger at Fri Jul  3 02:27:15 2015
    Exiting get_duke at Fri Jul  3 02:27:25 2015

So it appears that the implementation of `std::call_once` shipped with Visual
Studio 2012/2013 relies on some kind of a global lock, which causes even the
simple example above to misbehave.

The [complete code sample] to demonstrate the misbehaviour described above can
be found in this blog's repository.

[complete code sample]: {{ site.github.repository_url }}/tree/master/std_call_once_bug

Resolution
----------

So, since I couldn't submit the bug via Visual Studio's [Connect page], I wrote
to Mr. Lavavej directly, not hoping for an answer.
Amazingly, it took him less than a day to reply.
He told me he was planning to overhaul `std::call_once` for Visual Studio 2015.
Meanwhile, I had to stick to something else; I think I either dropped logging
from `Duke`'s constructor or initialized all the singleton instances manually
before actually using any of them.
In a few months, Mr. Lavavej replied to me that the bug has been fixed in
Visual Studio 2015 RTM.
I would like to thank him for the professionalism and responsibility he's
shown.
