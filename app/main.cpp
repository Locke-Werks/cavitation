#include <QApplication>
#include <QFontDatabase>
#include <QIcon>
#include <QMessageBox>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QStringList>
#include <QUrl>

#include <exception>

#include "chat_list_model.h"
#include "core_api.h"
#include "core_bridge.h"
#include "message_list_model.h"

namespace {

void registerBundledFonts()
{
    const QStringList paths = {
        QStringLiteral(":/fonts/fonts/ChakraPetch-Regular.ttf"),
        QStringLiteral(":/fonts/fonts/ChakraPetch-Medium.ttf"),
        QStringLiteral(":/fonts/fonts/ChakraPetch-SemiBold.ttf"),
        QStringLiteral(":/fonts/fonts/ChakraPetch-Bold.ttf"),
        QStringLiteral(":/fonts/fonts/Outfit-VariableFont.ttf"),
    };
    for (const QString& p : paths) {
        if (QFontDatabase::addApplicationFont(p) < 0)
            qWarning("failed to load bundled font %s", qPrintable(p));
    }
}

}  // namespace

int main(int argc, char* argv[])
{
    // Basic, not the Windows native style: the custom contentItem and
    // background overrides on ScrollBar, MenuItem and the rest are ignored by
    // FluentWinUI3, which would quietly undo half the theme.
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    // QApplication rather than QGuiApplication because the file picker is
    // QFileDialog, which is a widget.
    QApplication app(argc, argv);
    QApplication::setApplicationName(QStringLiteral("Cavitation"));
    QApplication::setOrganizationName(QStringLiteral("Locke Werks"));
    QApplication::setWindowIcon(QIcon(QStringLiteral(":/icons/cavitation.ico")));

    registerBundledFonts();

    const QString dataDir = cav::fromRust(core::default_data_dir());
    try {
        core::init_logger_at(cav::Utf8(dataDir));
    } catch (const std::exception& e) {
        // Losing the log file is survivable; losing the app over it is not.
        qWarning("logger init failed: %s", e.what());
    }

    // If the core will not open there is no session to run a window against,
    // so say why and stop rather than presenting an empty shell.
    cav::CoreBridge* bridge = nullptr;
    try {
        bridge = new cav::CoreBridge(dataDir);
    } catch (const std::exception& e) {
        QMessageBox::critical(
            nullptr, QStringLiteral("Cavitation"),
            QStringLiteral("The protocol core would not start.\n\n%1\n\nData directory:\n%2")
                .arg(QString::fromUtf8(e.what()), dataDir));
        return 1;
    }

    auto* chats = new cav::ChatListModel(bridge, bridge);
    auto* messages = new cav::MessageListModel(bridge, bridge);

    QQmlApplicationEngine engine;
    qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/qml/Theme.qml")),
                             "CAV", 1, 0, "Theme");

    engine.rootContext()->setContextProperty(QStringLiteral("Core"), bridge);
    engine.rootContext()->setContextProperty(QStringLiteral("ChatList"), chats);
    engine.rootContext()->setContextProperty(QStringLiteral("MessageModel"), messages);
    engine.rootContext()->setContextProperty(QStringLiteral("qtVersion"),
                                             QString::fromLatin1(qVersion()));

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        []() { QCoreApplication::exit(1); }, Qt::QueuedConnection);

    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));
    if (engine.rootObjects().isEmpty()) return 1;

    return app.exec();
}
