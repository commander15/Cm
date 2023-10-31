#include "cmplugin.h"

#include <QtQml/qqmlengine.h>

CmPlugin::CmPlugin(QObject *parent) :
    QQmlEngineExtensionPlugin(parent)
{
}

CmPlugin::~CmPlugin()
{
}

void CmPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    registerTypes(uri);
}

void CmPlugin::registerTypes(const char *uri)
{
    int major, minor;

    major = 1;
    minor = 0;

    //...
}
