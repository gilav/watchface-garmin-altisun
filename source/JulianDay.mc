using Toybox.Math as math;
using Toybox.Time as time;
using Toybox.Time.Gregorian as gregorian;
using Toybox.System as Sys;

// http://en.wikipedia.org/wiki/Sunrise_equation
// GL: look ok
class JulianDay{

	// orig
	function evaluateJulianDay(utcOffset)
	{		
		var timeInfo = gregorian.info(time.now().add(utcOffset), gregorian.FORMAT_SHORT); 
		//Sys.println("#### timeInfo="+timeInfo);
		
		var a = (14.0 - timeInfo.month)/12.0;
		//Sys.println("a="+a);
		var y = timeInfo.year + 4800.0 - a;
		//Sys.println("y="+y);
		var m = timeInfo.month + 12.0 * a - 3.0;
		//Sys.println("m="+m);
		var h = timeInfo.hour;
		var mn = timeInfo.min;
		//Sys.println("#### timeInfo: y=" +timeInfo.year+" ;m=" +timeInfo.month+" ;d=" +timeInfo.day+" ;h=" +timeInfo.hour+" ;mn=" +timeInfo.min);
		
		//var JDN = timeInfo.day.toLong() + ((153.0 * m  + 2.0) / 5.0).toLong() + (365*y).toLong() + (y/4.0).toLong() - (y/100.0).toLong() + (y/400.0).toLong() - 32045;
		var JDN = timeInfo.day + ((153.0 * m  + 2.0) / 5.0).toLong() + (365*y).toLong() + (y/4.0).toLong() - (y/100.0).toLong() + (y/400.0).toLong() - 32045;
		
		var aa = ((153.0 * m  + 2.0) / 5.0).toLong();
		//Sys.println("aa="+aa);
		
		var bb =  (365*y).toLong();
		//Sys.println("bb="+bb);
		
		var cc =  (y/4.0).toLong();
		//Sys.println("cc="+cc);
		
		var dd =  (y/100.0).toLong();
		//Sys.println("dd="+dd);
		
		var ee =  (y/400.0).toLong();
		//Sys.println("ee="+ee);
		
		var zz = timeInfo.day.toLong() + aa + bb + cc - dd + ee - 32045;
		//Sys.println("zz="+zz);
		
		//Sys.println("JDN:"+JDN);
		
		//var JD = JDN + (timeInfo.hour - 12.0)/24.0 + timeInfo.min/1440.0 + timeInfo.sec/(gregorian.SECONDS_PER_DAY);
		var JD = zz + (timeInfo.hour - 12.0)/24.0 + timeInfo.min/1440.0 + timeInfo.sec/(gregorian.SECONDS_PER_DAY);
	
		//Sys.println("Julian day:" + JD+"; JDN:"+JDN);
		
		return JD;	
	}
	
	
//***********************************************************************/
//* Name:    calcJD									*/
//* Type:    Function									*/
//* Purpose: Julian day from calendar day						*/
//* Arguments:										*/
//*   year : 4 digit year								*/
//*   month: January = 1								*/
//*   day  : 1 - 31									*/
//* Return value:										*/
//*   The Julian day corresponding to the date					*/
//* Note:											*/
//*   Number is returned for start of day.  Fractional days should be	*/
//*   added later.									*/
//***********************************************************************/
    function calcJD(year, month, day) {
        if (month <= 2) {
            year -= 1;
            month += 12;
        }
        var A = (year / 100).toLong();
        var B = 2 - A + (A / 4).toLong();

        var JD = (365.25 * (year + 4716)).toLong() + (30.6001 * (month + 1)).toLong() + day + B - 1524.5;
        return JD;
    }
	
	
	// mine
    /**
     * format a duration in msec into days, hours, mins
     *
     * @param msec
     * @return
     */
    function calcJDNow(utcOffset) {
        var timeInfo = gregorian.info(time.now().add(utcOffset), gregorian.FORMAT_SHORT); 
        var year = timeInfo.year;
        var month = timeInfo.month + 1; // Note: zero based!
        var day = timeInfo.year;
        var hour = timeInfo.hour;
        var minute = timeInfo.minute;
        var second = timeInfo.second;
        //int millis = now.get(Calendar.MILLISECOND);
        
        var dmsec = (hour*3600 + minute * 60 + second)*1000 + millis; 
        var dayFrac = day + (dmsec/84600000);
        Sys.out.println(" calcJDNow: year="+year+"; month="+month+"; day="+day+"  hour:"+hour+"; minute:"+minute+"; second:"+second+"; millis:"+millis);
        Sys.out.println(" dayFrac:"+dayFrac);
        
        var res = calcJD(year, month, dayFrac);
        Sys.out.println(" jday:"+res);
        
        return res;
    }
	
}