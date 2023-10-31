#include <QtCore/qcoreapplication.h>
#include <QtCore/qtextstream.h>

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    QTextStream out(stdout);

    for (int i(0); i < 10; ++i) {
        out << i;
    }

    return app.exec();
}
