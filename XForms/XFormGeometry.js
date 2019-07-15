/* Copyright 2019 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

.pragma library

.import QtQml 2.11 as QML
.import QtPositioning 5.11 as QtPos

//------------------------------------------------------------------------------

function pointsToPath(points) {
    var path = [];

    if (!Array.isArray(points)) {
        return path;
    }

    var coordinate;

    points.forEach(function (point) {
        if (Array.isArray(point)) {
            coordinate = QtPos.QtPositioning.coordinate(point[1], point[0]);
            if (coordinate.isValid) {
                path.push(coordinate);
            }
        } else if (isPointObject(point)) {
            coordinate = QtPos.QtPositioning.coordinate(point.y, point.x);
            if (coordinate.isValid) {
                path.push(coordinate);
            }
        }
    });

    return path;
}

//------------------------------------------------------------------------------

function pathArea(path) {
    if (path.length < 3) {
        return;
    }

    function signedArea(path, radius) {
        function toRadians(degrees) {
            return degrees / 180.0 * Math.PI;
        }

        function polarTriangleArea(tanPhi1, lambda1, tanPhi2, lambda2) {
            var deltaLambda = lambda1 - lambda2;
            var t = tanPhi1 * tanPhi2;

            return 2 * Math.atan2(t * Math.sin(deltaLambda), 1 + t * Math.cos(deltaLambda));
        }

        var total = 0;
        var coordinate = path[path.length - 1];
        var _tanPhi = Math.tan((Math.PI / 2 - toRadians(coordinate.latitude)) / 2);
        var _lambda = toRadians(coordinate.longitude);

        path.forEach(function (coordinate) {
            var tanPhi = Math.tan((Math.PI / 2 - toRadians(coordinate.latitude)) / 2);
            var lambda = toRadians(coordinate.longitude);

            total += polarTriangleArea(tanPhi, lambda, _tanPhi, _lambda);

            _tanPhi = tanPhi;
            _lambda = lambda;
        });

        return total * (radius * radius);
    }

    return Math.abs(signedArea(path, 6371009.0));
}

//--------------------------------------------------------------------------

function displayLength(length, locale) {
    switch (locale.measurementSystem) {
    case QML.Locale.ImperialUSSystem:
    case QML.Locale.ImperialUKSystem:
        var lengthFt = length * 3.28084;
        if (lengthFt < 1000) {
            return "%1 ft".arg(localeRound(lengthFt, 0, locale));
        } else {
            var lengthMiles = length * 0.000621371;
            return "%1 mi".arg(localeRound(lengthMiles, lengthMiles < 10 ? 1 : 0, locale));
        }

    default:
        if (length < 1000) {
            return "%1 m".arg(localeRound(length, 0, locale));
        } else {
            var lengthKm = length / 1000;
            return "%1 km".arg(localeRound(lengthKm, lengthKm < 10 ? 1 : 0, locale));
        }
    }
}

//--------------------------------------------------------------------------

function displayArea(area, locale) {
    switch (locale.measurementSystem) {
    case QML.Locale.ImperialUSSystem:
    case QML.Locale.ImperialUKSystem:
        var areaSquareFt = area * 10.7639;
        if (areaSquareFt < 1000) {
            return "%1 ft²".arg(localeRound(areaSquareFt, 0, locale));
        } else {
            var areaAcres = area * 0.000247105;
            return "%1 acres".arg(localeRound(areaAcres, areaAcres < 10 ? 2 : 1, locale));
        }

    default:
        if (area < 10000) {
            return "%1 m²".arg(localeRound(area, 0, locale));
        } else {
            var areaHectares = area / 10000;
            return "%1 hectares".arg(localeRound(areaHectares, areaHectares < 10 ? 2 : 1, locale))
        }
    }
}

//--------------------------------------------------------------------------

function localeRound(value, decimals, locale) {
    if (!decimals) {
        decimals = 0;
    }

    var p = Math.pow(10, decimals);

    return trimTrailingZeros((Math.round(value * p) / p).toLocaleString(locale, "f", decimals), locale);
}

//--------------------------------------------------------------------------

function trimTrailingZeros(text, locale) {
    var decimalPoint = locale ? locale.decimalPoint : ".";
    var zeroDigit = locale ? locale.zeroDigit : "0";

    if (text.indexOf(decimalPoint) <= 0) {
        return text;
    }

    var l = text.length;
    while (l > 0) {
        var c = text.charAt(l - 1);
        if (c === decimalPoint || c === zeroDigit) {
            l--;
        } else {
            break;
        }
    }

    return l < text.length ? text.substr(0, l) : text;
}

//------------------------------------------------------------------------------

function isPointObject(o) {
    return o !== null & typeof o === "object" && o === null || isFinite(o.x) && isFinite(o.y);
}

//------------------------------------------------------------------------------

function isPointsArray(a, ignoreNulls) {
    if (!Array.isArray(a)) {
        return false;
    }

    var isPoints = a.length > 0;
    for (var i = 0; i < a.length && isPoints; i++) {
        var o = a[i];

        isPoints = (ignoreNulls && (o === null || o === undefined)) || isPointObject(o);
    }

    return isPoints;
}

//------------------------------------------------------------------------------
