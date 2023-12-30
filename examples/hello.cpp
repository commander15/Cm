#include <iostream>
#include <vector>

class Shape
{
public:
    inline void draw()
    {drawShape(std::cout);}

    virtual void drawShape(std::ostream &stream) = 0;
};

class Line : public Shape
{
public:
    inline void drawShape(std::ostream &stream) override
    {stream << "----------" << std::endl;}
};

class Rectangle : public Shape
{
public:
    inline void drawShape(std::ostream &stream) override
    {
        stream << "+---------+" << std::endl;
        stream << "|         |" << std::endl;
        stream << "+---------+" << std::endl;
    }
};

int main()
{
    std::cout << "Hello World !" << std::endl;

    std::vector<Shape*> shapes;

    Line line;
    shapes.push_back(&line);

    Rectangle rectangle;
    shapes.push_back(&rectangle);

    shapes.push_back(&line);

    for (Shape *shape : shapes) {
        shape->draw();
        std::cout << std::endl;
    }

    return 0;
}
