// Copyright (c) 2016 Egor Tensin <Egor.Tensin@gmail.com>
// This file is part of the "C++ notes" project.
// For details, see https://github.com/egor-tensin/cpp-notes.
// Distributed under the MIT License.

#include <ctime>

#include <chrono>
#include <iostream>
#include <mutex>
#include <sstream>
#include <string>
#include <thread>

namespace
{
    template <typename Derived>
    class Singleton
    {
    public:
        static Derived& get_instance()
        {
            std::call_once(initialized_flag, &initialize_instance);
            return Derived::get_instance_unsafe();
        }

    protected:
        Singleton() = default;
        ~Singleton() = default;

        static Derived& get_instance_unsafe()
        {
            static Derived instance;
            return instance;
        }

    private:
        static void initialize_instance()
        {
            Derived::get_instance_unsafe();
        }

        static std::once_flag initialized_flag;

        Singleton(const Singleton&) = delete;
        Singleton& operator=(const Singleton&) = delete;
    };

    template <typename Derived>
    std::once_flag Singleton<Derived>::initialized_flag;

    class Logger : public Singleton<Logger>
    {
    public:
        Logger& operator<<(const char*)
        {
            return *this;
        }

    private:
        Logger()
        {
            std::this_thread::sleep_for(std::chrono::seconds{3});
        }

        ~Logger() = default;

        friend class Singleton<Logger>;
    };

    class Duke : public Singleton<Duke>
    {
    private:
        Duke()
        {
            Logger::get_instance() << "started Duke's initialization";
            std::this_thread::sleep_for(std::chrono::seconds{10});
            Logger::get_instance() << "finishing Duke's initialization";
        }

        ~Duke() = default;

        friend class Singleton<Duke>;
    };

    std::mutex timestamp_mtx;

    std::string get_timestamp()
    {
        std::lock_guard<std::mutex> lck{timestamp_mtx};
        const auto tt = std::time(NULL);
        return std::ctime(&tt);
    }

    void entered(const char* f)
    {
        std::ostringstream oss;
        oss << "Entered " << f << " at " << get_timestamp();
        std::cout << oss.str();
    }

    void exiting(const char* f)
    {
        std::ostringstream oss;
        oss << "Exiting " << f << " at " << get_timestamp();
        std::cout << oss.str();
    }

    void get_logger()
    {
        entered(__FUNCTION__);
        Logger::get_instance();
        exiting(__FUNCTION__);
    }

    void get_duke()
    {
        entered(__FUNCTION__);
        Duke::get_instance();
        exiting(__FUNCTION__);
    }
}

int main()
{
    std::thread t1{&get_duke};
    std::thread t2{&get_logger};
    t1.join();
    t2.join();
    return 0;
}
