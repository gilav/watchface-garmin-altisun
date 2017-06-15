using Toybox.Math as math;
using Toybox.Time as time;
using Toybox.System as Sys;

//

//from: view-source:http://www.esrl.noaa.gov/gmd/grad/solcalc/sunrise.html

//<p>Please note that this web page is the old version of the NOAA Solar Calculator.
//Back when this calculator was first created, we decided to use a non-standard
//definition of longitude and time zone, to make coordinate entry less awkward.
//
//So on this page, both longitude and time zone are defined as positive to the
//west, instead of the international standard of positive to the east of the
//Prime Meridian.
//
class SunsetSunrise{


//***********************************************************************/
//* Name:    calcHourAngleSunrise							*/
//* Type:    Function									*/
//* Purpose: calculate the hour angle of the sun at sunrise for the	*/
//*			latitude								*/
//* Arguments:										*/
//*   lat : latitude of observer in degrees					*/
//*	solarDec : declination angle of sun in degrees				*/
//* Return value:										*/
//*   hour angle of sunrise in radians						*/
//***********************************************************************/
    function calcHourAngleSunrise(lat, solarDec) {
        var latRad = degToRad(lat);
        var sdRad = degToRad(solarDec);

        var HA = (Math.acos(Math.cos(degToRad(90.833)) / (Math.cos(latRad) * Math.cos(sdRad)) - Math.tan(latRad) * Math.tan(sdRad)));

        return HA; // in radians
    }


//***********************************************************************/
//* Name:    calcHourAngleSunset							*/
//* Type:    Function									*/
//* Purpose: calculate the hour angle of the sun at sunset for the	*/
//*			latitude								*/
//* Arguments:										*/
//*   lat : latitude of observer in degrees					*/
//*	solarDec : declination angle of sun in degrees				*/
//* Return value:										*/
//*   hour angle of sunset in radians						*/
//***********************************************************************/
    function calcHourAngleSunset(lat, solarDec) {
        var latRad = degToRad(lat);
        var sdRad = degToRad(solarDec);

        var HA = (Math.acos(Math.cos(degToRad(90.833)) / (Math.cos(latRad) * Math.cos(sdRad)) - Math.tan(latRad) * Math.tan(sdRad)));

        return -HA; // in radians
    }

//***********************************************************************/
//* Name:    calGeomMeanLongSun							*/
//* Type:    Function									*/
//* Purpose: calculate the Geometric Mean Longitude of the Sun		*/
//* Arguments:										*/
//*   t : number of Julian centuries since J2000.0				*/
//* Return value:										*/
//*   the Geometric Mean Longitude of the Sun in degrees			*/
//***********************************************************************/
    function calcGeomMeanLongSun(t) {
        var L0 = 280.46646 + t * (36000.76983 + 0.0003032 * t);
        
        //while (L0 > 360.0) {
        //    L0 -= 360.0;
        //}
        //while (L0 < 0.0) {
        //    L0 += 360.0;
        //}
        
        return modulus(L0, 360); // in degrees
    }


//***********************************************************************/
//* Name:    calGeomAnomalySun							*/
//* Type:    Function									*/
//* Purpose: calculate the Geometric Mean Anomaly of the Sun		*/
//* Arguments:										*/
//*   t : number of Julian centuries since J2000.0				*/
//* Return value:										*/
//*   the Geometric Mean Anomaly of the Sun in degrees			*/
//***********************************************************************/
    function calcGeomMeanAnomalySun(t) {
        var M = 357.52911 + t * (35999.05029 - 0.0001537 * t);
        return M; // in degrees
    }

//***********************************************************************/
//* Name:    calcEccentricityEarthOrbit						*/
//* Type:    Function									*/
//* Purpose: calculate the eccentricity of earth's orbit			*/
//* Arguments:										*/
//*   t : number of Julian centuries since J2000.0				*/
//* Return value:										*/
//*   the unitless eccentricity							*/
//***********************************************************************/
    function calcEccentricityEarthOrbit(t) {
        var e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
        return e; // unitless
    }

//***********************************************************************/
//* Name:    calcSunEqOfCenter							*/
//* Type:    Function									*/
//* Purpose: calculate the equation of center for the sun			*/
//* Arguments:										*/
//*   t : number of Julian centuries since J2000.0				*/
//* Return value:										*/
//*   in degrees										*/
//***********************************************************************/
    function calcSunEqOfCenter(t) {
        var m = calcGeomMeanAnomalySun(t);

        var mrad = degToRad(m);
        var sinm = Math.sin(mrad);
        var sin2m = Math.sin(mrad + mrad);
        var sin3m = Math.sin(mrad + mrad + mrad);

        var C = sinm * (1.914602 - t * (0.004817 + 0.000014 * t)) + sin2m * (0.019993 - 0.000101 * t) + sin3m * 0.000289;
        return C; // in degrees
    }




//***********************************************************************/
//* Name:    calcSunTrueLong								*/
//* Type:    Function									*/
//* Purpose: calculate the true longitude of the sun				*/
//* Arguments:										*/
//*   t : number of Julian centuries since J2000.0				*/
//* Return value:										*/
//*   sun's true longitude in degrees						*/
//***********************************************************************/
    function calcSunTrueLong(t) {
        var l0 = calcGeomMeanLongSun(t);
        var c = calcSunEqOfCenter(t);

        var O = l0 + c;
        return O; // in degrees
    }

//***********************************************************************/
//* Name:    calcSunTrueAnomaly							*/
//* Type:    Function									*/
//* Purpose: calculate the true anamoly of the sun				*/
//* Arguments:										*/
//*   t : number of Julian centuries since J2000.0				*/
//* Return value:										*/
//*   sun's true anamoly in degrees							*/
//***********************************************************************/
    function calcSunTrueAnomaly(t) {
        var m = calcGeomMeanAnomalySun(t);
        var c = calcSunEqOfCenter(t);

        var v = m + c;
        return v; // in degrees
    }

//***********************************************************************/
//* Name:    calcSunRadVector								*/
//* Type:    Function									*/
//* Purpose: calculate the distance to the sun in AU				*/
//* Arguments:										*/
//*   t : number of Julian centuries since J2000.0				*/
//* Return value:										*/
//*   sun radius vector in AUs							*/
//***********************************************************************/
    function calcSunRadVector(t) {
        var v = calcSunTrueAnomaly(t);
        var e = calcEccentricityEarthOrbit(t);

        var R = (1.000001018 * (1 - e * e)) / (1 + e * Math.cos(degToRad(v)));
        return R; // in AUs
    }

//***********************************************************************/
//* Name:    calcSunApparentLong							*/
//* Type:    Function									*/
//* Purpose: calculate the apparent longitude of the sun			*/
//* Arguments:										*/
//*   t : number of Julian centuries since J2000.0				*/
//* Return value:										*/
//*   sun's apparent longitude in degrees						*/
//***********************************************************************/
    function calcSunApparentLong(t) {
        var o = calcSunTrueLong(t);

        var omega = 125.04 - 1934.136 * t;
        var lambda = o - 0.00569 - 0.00478 * Math.sin(degToRad(omega));
        return lambda; // in degrees
    }

//***********************************************************************/
//* Name:    calcMeanObliquityOfEcliptic						*/
//* Type:    Function									*/
//* Purpose: calculate the mean obliquity of the ecliptic			*/
//* Arguments:										*/
//*   t : number of Julian centuries since J2000.0				*/
//* Return value:										*/
//*   mean obliquity in degrees							*/
//***********************************************************************/
    function calcMeanObliquityOfEcliptic( t) {
        var seconds = 21.448 - t * (46.8150 + t * (0.00059 - t * (0.001813)));
        var e0 = 23.0 + (26.0 + (seconds / 60.0)) / 60.0;
        return e0; // in degrees
    }

    //***********************************************************************/
//* Name:    calcObliquityCorrection						*/
//* Type:    Function									*/
//* Purpose: calculate the corrected obliquity of the ecliptic		*/
//* Arguments:										*/
//*   t : number of Julian centuries since J2000.0				*/
//* Return value:										*/
//*   corrected obliquity in degrees						*/
//***********************************************************************/
    function calcObliquityCorrection(t) {
        var e0 = calcMeanObliquityOfEcliptic(t);

        var omega = 125.04 - 1934.136 * t;
        var e = e0 + 0.00256 * Math.cos(degToRad(omega));
        return e; // in degrees
    }

//***********************************************************************/
//* Name:    calcSunRtAscension							*/
//* Type:    Function									*/
//* Purpose: calculate the right ascension of the sun				*/
//* Arguments:										*/
//*   t : number of Julian centuries since J2000.0				*/
//* Return value:										*/
//*   sun's right ascension in degrees						*/
//***********************************************************************/
    function calcSunRtAscension( t) {
        var e = calcObliquityCorrection(t);
        var lambda = calcSunApparentLong(t);

        var tananum = (Math.cos(degToRad(e)) * Math.sin(degToRad(lambda)));
        var tanadenom = (Math.cos(degToRad(lambda)));
        var alpha = radToDeg(Math.atan2(tananum, tanadenom));
        //Sys.println("  calcSunRtAscension deg:"+alpha);
        return alpha; // in degrees
    }

//***********************************************************************/
//* Name:    calcSunDeclination							*/
//* Type:    Function									*/
//* Purpose: calculate the declination of the sun				*/
//* Arguments:										*/
//*   t : number of Julian centuries since J2000.0				*/
//* Return value:										*/
//*   sun's declination in degrees							*/
//***********************************************************************/
    function calcSunDeclination( t) {
        var e = calcObliquityCorrection(t);
        var lambda = calcSunApparentLong(t);

        var sint = Math.sin(degToRad(e)) * Math.sin(degToRad(lambda));
        var theta = radToDeg(Math.asin(sint));
        
        //Sys.println("  calcSunDeclination deg:"+theta);
        return theta; // in degrees
    }

//***********************************************************************/
//* Name:    calcTimeJulianCent							*/
//* Type:    Function									*/
//* Purpose: convert Julian Day to centuries since J2000.0.			*/
//* Arguments:										*/
//*   jd : the Julian Day to convert						*/
//* Return value:										*/
//*   the T value corresponding to the Julian Day				*/
//***********************************************************************/
    function calcTimeJulianCent( jd) {
        var T = (jd - 2451545.0) / 36525.0;
        return T;
    }

//***********************************************************************/
//* Name:    calcJDFromJulianCent							*/
//* Type:    Function									*/
//* Purpose: convert centuries since J2000.0 to Julian Day.			*/
//* Arguments:										*/
//*   t : number of Julian centuries since J2000.0				*/
//* Return value:										*/
//*   the Julian Day corresponding to the t value				*/
//***********************************************************************/
    function calcJDFromJulianCent(t) {
        var JD = t * 36525.0 + 2451545.0;
        return JD;
    }

//***********************************************************************/
//* Name:    calcSolNoonUTC								*/
//* Type:    Function									*/
//* Purpose: calculate the Universal Coordinated Time (UTC) of solar	*/
//*		noon for the given day at the given location on earth		*/
//* Arguments:										*/
//*   t : number of Julian centuries since J2000.0				*/
//*   longitude : longitude of observer in degrees				*/
//* Return value:										*/
//*   time in minutes from zero Z							*/
//***********************************************************************/
    function calcSolNoonUTC( t,  longitude) {
        // First pass uses approximate solar noon to calculate eqtime
        var tnoon = calcTimeJulianCent(calcJDFromJulianCent(t) + longitude / 360.0);
        var eqTime = calcEquationOfTime(tnoon);
        var solNoonUTC = 720 + (longitude * 4) - eqTime; // min

        var newt = calcTimeJulianCent(calcJDFromJulianCent(t) - 0.5 + solNoonUTC / 1440.0);

        eqTime = calcEquationOfTime(newt);
        // var solarNoonDec = calcSunDeclination(newt);
        solNoonUTC = 720 + (longitude * 4) - eqTime; // min

        return solNoonUTC;
    }

//***********************************************************************/
//* Name:    calcEquationOfTime							*/
//* Type:    Function									*/
//* Purpose: calculate the difference between true solar time and mean	*/
//*		solar time									*/
//* Arguments:										*/
//*   t : number of Julian centuries since J2000.0				*/
//* Return value:										*/
//*   equation of time in minutes of time						*/
//***********************************************************************/
    function calcEquationOfTime( t) {
        var epsilon = calcObliquityCorrection(t);
        var l0 = calcGeomMeanLongSun(t);
        var e = calcEccentricityEarthOrbit(t);
        var m = calcGeomMeanAnomalySun(t);

        var y = Math.tan(degToRad(epsilon) / 2.0);
        y *= y;

        var sin2l0 = Math.sin(2.0 * degToRad(l0));
        var sinm = Math.sin(degToRad(m));
        var cos2l0 = Math.cos(2.0 * degToRad(l0));
        var sin4l0 = Math.sin(4.0 * degToRad(l0));
        var sin2m = Math.sin(2.0 * degToRad(m));

        var Etime = y * sin2l0 - 2.0 * e * sinm + 4.0 * e * y * sinm * cos2l0
                - 0.5 * y * y * sin4l0 - 1.25 * e * e * sin2m;

        //Sys.println("  calcEquationOfTime (minutes of time):"+(radToDeg(Etime) * 4.0));
        return radToDeg(Etime) * 4.0;	// in minutes of time
    }

//***********************************************************************/
//* Name:    calcSunsetUTC								*/
//* Type:    Function									*/
//* Purpose: calculate the Universal Coordinated Time (UTC) of sunset	*/
//*			for the given day at the given location on earth	*/
//* Arguments:										*/
//*   JD  : julian day									*/
//*   latitude : latitude of observer in degrees; POSITIVE TO NORTH				*/
//*   longitude : longitude of observer in degrees; POSITIVE TO WEST				*/
//* Return value:										*/
//*   time in minutes from zero Z							*/
//***********************************************************************/
    function calcSunsetUTC( JD,  latitude,  longitude) {
        var t = calcTimeJulianCent(JD);

        // *** Find the time of solar noon at the location, and use
        //     that declination. This is better than start of the 
        //     Julian day
        var noonmin = calcSolNoonUTC(t, longitude);
        var tnoon = calcTimeJulianCent(JD + noonmin / 1440.0);

        // First calculates sunrise and approx length of day
        var eqTime = calcEquationOfTime(tnoon);
        var solarDec = calcSunDeclination(tnoon);
        var hourAngle = calcHourAngleSunset(latitude, solarDec);

        var delta = longitude - radToDeg(hourAngle);
        var timeDiff = 4 * delta;
        var timeUTC = 720 + timeDiff - eqTime;

        // first pass used to include fractional day in gamma calc
        var newt = calcTimeJulianCent(calcJDFromJulianCent(t) + timeUTC / 1440.0);
        eqTime = calcEquationOfTime(newt);
        solarDec = calcSunDeclination(newt);
        hourAngle = calcHourAngleSunset(latitude, solarDec);

        delta = longitude - radToDeg(hourAngle);
        timeDiff = 4 * delta;
        timeUTC = 720 + timeDiff - eqTime; // in minutes

        return timeUTC;
    }

//***********************************************************************/
//* Name:    calcSunriseUTC								*/
//* Type:    Function									*/
//* Purpose: calculate the Universal Coordinated Time (UTC) of sunrise	*/
//*			for the given day at the given location on earth	*/
//* Arguments:										*/
//*   JD  : julian day									*/
//*   latitude : latitude of observer in degrees; POSITIVE TO NORTH				*/
//*   longitude : longitude of observer in degrees; POSITIVE TO WEST				*/
//* Return value:										*/
//*   time in minutes from zero Z							*/
//***********************************************************************/
    function calcSunriseUTC( JD,  latitude,  longitude) {
        var t = calcTimeJulianCent(JD);
        //Sys.println("#### JD="+JD+"; t="+t);

		// *** Find the time of solar noon at the location, and use
        //     that declination. This is better than start of the 
        //     Julian day
        var noonmin = calcSolNoonUTC(t, longitude);
        var tnoon = calcTimeJulianCent(JD + noonmin / 1440.0);

		// *** First pass to approximate sunrise (using solar noon)
        var eqTime = calcEquationOfTime(tnoon);
        var solarDec = calcSunDeclination(tnoon);
        var hourAngle = calcHourAngleSunrise(latitude, solarDec);

        var delta = longitude - radToDeg(hourAngle);
        var timeDiff = 4 * delta;	// in minutes of time
        var timeUTC = 720 + timeDiff - eqTime;	// in minutes

		//Sys.println("eqTime = " + eqTime + "\nsolarDec = " + solarDec + "\ntimeUTC = " + timeUTC);
		// *** Second pass includes fractional jday in gamma calc
        var newt = calcTimeJulianCent(calcJDFromJulianCent(t) + timeUTC / 1440.0);
        eqTime = calcEquationOfTime(newt);
        solarDec = calcSunDeclination(newt);
        hourAngle = calcHourAngleSunrise(latitude, solarDec);
        delta = longitude - radToDeg(hourAngle);
        timeDiff = 4 * delta;
        timeUTC = 720 + timeDiff - eqTime; // in minutes

		//Sys.println("eqTime = " + eqTime + "\nsolarDec = " + solarDec + "\ntimeUTC = " + timeUTC);
        return timeUTC;
    }





	//
	function degToRad(degrees)
	{
		return (degrees * math.PI) / 180.0;
	}
	// 
	function radToDeg(rad)
	{
		return (rad * 180.0) / math.PI;
	}
	
	//! Perform a modulus on two positive (decimal) numbers, i.e. 'a' mod 'n'
	//! 'a' is divident and 'n' is the divisor
	function modulus(a, n)
	{
		return a - (a / n).toLong() * n;
	}
}