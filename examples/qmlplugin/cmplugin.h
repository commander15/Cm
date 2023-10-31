#ifndef CMPLUGIN_H
#define CMPLUGIN_H

#include <QtQml/qqmlextensionplugin.h>

class CmPlugin : public QQmlEngineExtensionPlugin
{
    Q_OBJECT

public:
    explicit CmPlugin(QObject *parent = nullptr);
    ~CmPlugin();

    void initializeEngine(QQmlEngine *engine, const char *uri) override;
    void registerTypes(const char *uri);
};

#endif // CMPLUGIN_H
