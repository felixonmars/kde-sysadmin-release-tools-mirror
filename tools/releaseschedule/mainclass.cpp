#include "mainclass.h"
#include "ui_mainclass.h"

#include <QApplication>
#include <QDebug>

MainClass::MainClass(QWidget *parent)
    : QMainWindow(parent), ui(new Ui::MainClass)
{
    ui->setupUi(this);
    connect( ui->generateButton, SIGNAL(clicked()),
             SLOT( slotGenerateTechbase() ) );
    connect( ui->icalButton, SIGNAL(clicked()),
             SLOT( slotGenerateICal() ) );
}

MainClass::~MainClass()
{
    delete ui;
}

QString MainClass::explanation( Events event )
{
    QString desc;
    switch ( event ) {
        case sffreeze :
                desc = "Trunk is frozen for feature commits that are not listed "
                       "in the  planned feature document. Only bugfixes and the "
                       "code implementing the listed features are to be committed "
                       "after this date. The feature list also closes today.\n\n"
                       "Features not already finished or not listed on the planned "
                       "features page will have to wait until the next KDE SC release.";
                break;
        case hffreeze :
                desc = "Trunk is frozen for all feature commits, even those listed "
                       "in the planned feature document. Only bug fixes are allowed.";
                break;
        case depfreeze :
                desc = "From this moment on it is not allowed to add new "
                       "dependencies or bump dependencies versions. It is possible "
                       "to get an exception for this. Post the patch to reviewboard "
                       "and add the release-team as reviewer. We will check if the "
                       "dependency is needed and is available on all platforms.\n\n"
                       "In other words: If you have a feature that requires a new "
                       "dependency or a version of a dependency that is higher than "
                       "currently checked for in the build system, you need to have "
                       "committed this change before this date.";
                break;
        case safreeze :
                desc = "To allow the bindings people to have proper time to do "
                       "their work in preparation to the final release, the API "
                       "should now be mostly fixed. Changing API is allowed, but "
                       "commits have to be cc'ed to the kde-bindings mailinglist. "
                       "This is including older APIs and newly introduced "
                       "libraries/APIs.";
                break;
        case hafreeze :
                desc = "To allow the bindings people to have proper time to do "
                       "there work in preparation to the final release, the API "
                       "is now frozen. No more changes to APIs or header files "
                       "(except docs) after this date, including older APIs and "
                       "newly introduced libraries/APIs.";
                break;
        case smfreeze :
                desc = "All translated messages (GUI strings) are frozen on this "
                       "date. Only previously untranslated strings or clear errors "
                       "in strings can be fixed. No major new strings changes should "
                       "be done. It is ok to remove strings. Exception: Artwork "
                       "(try to keep the number of new strings low anyways). "
                       "Exception: Typo fixes can be fixed until the Hard Message Freeze, "
                       "but you have to mail kde-i18n-doc saying you made a typo fix "
                       "change.";
                break;
        case hmfreeze :
                desc = "Up to now you were able to do typo changes, but you had "
                       "to mail kde-i18n-doc saying you made a typo fix change. "
                       "From this moment on you need an explicit ok beforehand from "
                       "kde-i18n-doc for every single string change.";
                break;
        case betatag :
                desc = "Trunk is frozen for beta release tagging. Only urgent fixes, "
                       "such as those fixing compilation errors, should be committed. "
                       "The usual beta rules apply as soon as the Beta tarballs have "
                       "been generated.";
                break;
        case betarelease :
                desc = "The beta becomes available for general consumption.";
                break;
        case rctag :
                desc = "Trunk is frozen for release candidate tagging. Only urgent fixes, "
                       "such as those fixing compilation errors, should be committed. ";
                break;
        case rcrelease :
                desc = "The release candidate is tagged from the branch. Only urgent "
                       "fixes, such as those fixing compilation errors, should be committed."
                       "As soon as the RC has been confirmed to build it will be released "
                       "immediately.";
                break;
        case finaltag :
                desc = "The branch is frozen for final release tagging. Only urgent fixes, "
                       "such as those fixing compilation errors, should be committed. ";
                break;
        case finalrelease :
                desc = "Final release is released for general consumption.";
                break;
        case docfreeze :
                desc = "No more substantive changes to documentation or handbooks "
                       "after this date. Typos, spelling and simple grammar changes "
                       "are permitted.";
                break;
        case tagfreeze :
                desc = "During tagging freeze only compilation fixes for all "
                       "platforms are allowed to be committed. Everything else "
                       "(even showstopper fixes) *have* to be run through reviewboard, "
                       "with the release-team and the affected maintainers as reviewer. ";
                break;
        case artfreeze :
                desc = "All artwork is frozen on this date. No new artwork should "
                       "be added. Existing artwork can continue to be tweaked and "
                       "fixed.\n\nNo new additions to the language bindings, except "
                       "optional bindings as permitting by the kde-bindings team.";
                break;
        default :
                desc = "Unknown freeze, don't honor it :)";
            }
    return desc;
}

QString MainClass::title( Events event, const QString& version )
{
    QString desc;
    switch ( event ) {
        case sffreeze :
                desc = "Soft Feature Freeze";
                break;
        case hffreeze :
                desc = "Hard Feature Freeze";
                break;
        case depfreeze :
                desc = "Dependency Freeze";
                break;
        case safreeze :
                desc = "Soft API Freeze";
                break;
        case hafreeze :
                desc = "Hard API Freeze";
                break;
        case smfreeze :
                desc = "Soft Message Freeze";
                break;
        case hmfreeze :
                desc = "Hard Message Freeze";
                break;
        case betatag :
                desc = QString("Beta %1 Tagging").arg( version );
                break;
        case betarelease :
                desc = QString("Beta %1 Release").arg( version );
                break;
        case rctag :
                desc = QString("Release Candidate %1 Tagging").arg( version );
                break;
        case rcrelease :
                desc = QString("Release Candidate %1 Release").arg( version );
                break;
        case finaltag :
                desc = "Final Tag";
                break;
        case finalrelease :
                desc = "Release";
                break;
        case docfreeze :
                desc = "Documentatin Freeze";
                break;
        case tagfreeze :
                desc = QString("Tagging Freeze %1").arg( version );
                break;
        case artfreeze :
                desc = "Artwork and Bindings Freeze";
                break;
        default :
                desc = "Unknown freeze, don't honor it :)";
            }
    return desc;
}

QPair<QString, QString> MainClass::makePair( Events event, const QString& version )
{
    return qMakePair( title( event, version ), explanation( event ) );
}

QMultiMap<QDate, QPair<QString, QString> > MainClass::generateTimeline()
{
    QMultiMap<QDate, QPair<QString, QString> > timeline;
    QDate release = ui->releaseDate->date();
    timeline.insert( release, makePair( finalrelease ) );

    // fixed freezes, amount of weeks, minus 2 days to not clash with tags, releases.
    timeline.insert( release.addDays( ( ui->docFreeze->value() * -7 ) - 2),
                     makePair( docfreeze ) );
    timeline.insert( release.addDays( ( ui->artFreeze->value() * -7 ) - 2),
                     makePair( artfreeze ) );
    timeline.insert( release.addDays( ( ui->hardMessageFreeze->value() * -7 ) -2),
                     makePair( hmfreeze ) );
    timeline.insert( release.addDays( ( ui->hardApiFreeze->value() * -7 ) -2),
                     makePair( hafreeze ) );

    // tag before release
    QDate timelinePoint( release );
    timelinePoint = timelinePoint.addDays( ui->tagBeforeRelease->value() * -1 );
    timeline.insert(  timelinePoint, makePair( finaltag ) );

    // release candidates before tagging final release
    for ( int i = ui->rcAmount->text().toInt(); i > 0; --i ) {
        timelinePoint = timelinePoint.addDays( ui->rcInterval->value() * -7 );
        timeline.insert( timelinePoint, makePair( rcrelease, QString::number( i ) ) );

        // tagging is a bit earlier.
        timeline.insert( timelinePoint.addDays( ui->rcTagBeforeRelease->value() * -1 ),
                         makePair( rctag, QString::number( i ) ) );

        // one day tagging freeze around RC's.
        timeline.insert( timelinePoint.addDays( (ui->rcTagBeforeRelease->value() * -1) - 1 ),
                         makePair( tagfreeze, " for Release Candidate " + QString::number( i ) ) );
    }

    // beta releases before the rc's
    for ( int i = ui->betaAmount->text().toInt(); i > 0; --i ) {
        timelinePoint = timelinePoint.addDays( ui->betaInterval->value() * -7 );
        timeline.insert( timelinePoint, makePair( betarelease, QString::number( i ) ) );

        // tagging is a bit earlier.
        timeline.insert( timelinePoint.addDays( ui->betaTagBeforeRelease->value() * -1 ),
                         makePair( betatag, QString::number( i ) ) );
    }

    // Stuff before tagging of the first beta.
    timelinePoint = timelinePoint.addDays( ui->betaTagBeforeRelease->value() * -1 );
    timeline.insert( timelinePoint.addDays( ui->softFeatureFreeze->value() * -7 ),
                     makePair( sffreeze ) );
    timeline.insert( timelinePoint.addDays( ui->hardFeatureFreeze->value() * -7 ),
                     makePair( hffreeze ) );
    timeline.insert( timelinePoint.addDays( ui->dependencyFreeze->value() * -7 ),
                     makePair( depfreeze ) );
    timeline.insert( timelinePoint.addDays( ui->sofApiFreeze->value() * -7 ),
                     makePair( safreeze ) );
    timeline.insert( timelinePoint.addDays( ui->softMessageFreeze->value() * -7 ),
                     makePair( smfreeze ) );
    return timeline;
}

void MainClass::slotGenerateTechbase()
{
    QMultiMap<QDate, QPair<QString, QString> > timeline = generateTimeline();

    QLocale english( QLocale::English );     // Dates in english
    QString text;
    QMap<QDate, QPair<QString, QString> >::const_iterator i;
    for (i = timeline.constBegin(); i != timeline.constEnd(); ++i)
     text.append( "=== " + english.toString( i.key() ) + ": " + i.value().first + " ===\n" +
                  i.value().second + "\n\n");

    ui->schedule->setText( text );
}

void MainClass::slotGenerateICal()
{
    QMultiMap<QDate, QPair<QString, QString> > timeline = generateTimeline();
    QLocale english( QLocale::English );     // Dates in english
    QString text;
    text.append( "BEGIN:VCALENDAR\n" );
    text.append( "VERSION:2.0\n");
    text.append( "PRODID:-//hacksw/handcal//NONSGML v1.0//EN\n\n");

    QMap<QDate, QPair<QString, QString> >::const_iterator i;
    for (i = timeline.constBegin(); i != timeline.constEnd(); ++i) {
        text.append( "BEGIN:VEVENT\n");
        QDateTime dt( i.key() );
        dt.setTime( QTime( 23, 59 ) );
        text.append( "DTSTART: " + dt.toString( Qt::ISODate ) + "Z\n" );
        text.append( "SUMMARY: " + i.value().first + "\n" );
        QString desc(i.value().second);
        desc.replace('\n',' ');
        text.append( "DESCRIPTION: " + desc + "\n" );
        text.append( "END:VEVENT\n\n");

    }

    text.append( "END:VCALENDAR\n");
    ui->schedule->setText( text );
}
