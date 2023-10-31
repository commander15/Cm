import QtQuick 2.14
import QtQuick.Controls 2.14

import QtMultimedia 5.14
import QtSensors 5.14

ApplicationWindow {
    title: "Cm"
    width: 320
    height: 240
    visible: true

    VideoOutput {
        id: video

        fillMode: VideoOutput.PreserveAspectCrop
        autoOrientation: true
        source: cam

        anchors.fill: parent

        Label {
            id: subject

            text: "👅" + light.lux
            font.pointSize: 32
            font.bold: true
            color: "blue"

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignBottom

            y: parent.height - height - 64

            PropertyAnimation on x {
                id: subjectX

                onToChanged: start()
            }

            PropertyAnimation on y {
                id: subjectY

                onToChanged: start()
            }
        }
    }

    Camera {
        id: cam

        position: Camera.FrontFace

        Component.onCompleted: start()
    }

    Accelerometer {
        active: true

        onReadingChanged: function() {
            subjectX.to = subject.x - (reading.x * 5);
            subjectY.to = subject.y + (reading.y * 5);
        }
    }

    LightSensor {
        id: light

        property var lux

        active: true

        onReadingChanged: function() {
            lux = reading.illuminance;
            console.log(reading.illuminance);
        }

        Component.onCompleted: function() {
            start();
        }

        onErrorChanged: console.log("Error " + error);
    }

    ProximitySensor {
        active: true

        onReadingChanged: function() {
            subject.color = (reading.near ? "red" : "blue");
        }
    }
}
