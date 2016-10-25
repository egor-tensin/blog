#include <iostream>
#include <utility>

namespace
{
    class C
    {
    public:
        explicit C()
        {
            std::cout << "\tC::C()\n";
        }

        C(C&&) noexcept
        {
            std::cout << "\tC::C(C&&)\n";
        }

        C(const C&)
        {
            std::cout << "\tC::C(const C&)\n";
        }

        C& operator=(C&&) noexcept
        {
            std::cout << "\tC::operator=(C&&)\n";
            return *this;
        }

        C& operator=(const C&)
        {
            std::cout << "\tC::operator=(const C&)\n";
            return *this;
        }

        ~C()
        {
            std::cout << "\tC::~C()\n";
        }
    };

    C make_rvo()
    {
        return C{};
    }

    C make_nrvo()
    {
        C c;
        return c;
    }
}

int main()
{
    {
        std::cout << "C c\n";
        C c;
    }
    {
        std::cout << "C c(make_rvo())\n";
        C c(make_rvo());
    }
    {
        std::cout << "C c{make_rvo()}\n";
        C c{make_rvo()};
    }
    {
        std::cout << "C c = make_rvo()\n";
        C c = make_rvo();
    }
    return 0;
}
