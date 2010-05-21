#include <QtGui/QApplication>
#include "mainclass.h"

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    MainClass w;
    w.show();
    return a.exec();
}
