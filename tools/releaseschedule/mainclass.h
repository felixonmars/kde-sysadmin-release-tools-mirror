#ifndef MAINCLASS_H
#define MAINCLASS_H

#include <QtGui/QMainWindow>

namespace Ui
{
    class MainClass;
}

class MainClass : public QMainWindow
{
    Q_OBJECT

public:
    enum Events { sffreeze, hffreeze, safreeze, hafreeze,
                  depfreeze, docfreeze, tagfreeze, artfreeze,
                  smfreeze, hmfreeze, betatag, betarelease,
                  rctag, rcrelease, finaltag, finalrelease };
    MainClass(QWidget *parent = 0);
    ~MainClass();

private slots:
    void slotGenerate();

private:
    QPair<QString, QString> makePair( Events event, const QString& version = QString() );
    QString title( Events event, const QString& version = QString() );
    QString explanation( Events event );
    Ui::MainClass *ui;
};

#endif // MAINCLASS_H
