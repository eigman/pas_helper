#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDir>
#include <QQuickStyle>
#include <QQuickWindow>

#include "core/AppController.h"

int main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("Report Assistant"));
    app.setApplicationVersion(QStringLiteral("0.1.0"));
    app.setOrganizationName(QStringLiteral("ReportAssistant"));

    // Use Material style
    QQuickStyle::setStyle(QStringLiteral("Material"));

    // Set up controller
    AppController controller;
    const QString binaryDir = QDir(QCoreApplication::applicationDirPath()).absolutePath();
    controller.initialize(binaryDir);

    // Set up QML engine
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("controller"), &controller);

    const QUrl url(QStringLiteral("qrc:/ReportAssistant/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
