using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys; 
using Toybox.Time as Time;
using Toybox.Timer as Timer;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.Application as App;
using Toybox.ActivityMonitor as ActMon;
using Toybox.Activity as Act;

//
// Version 0.8 
// last change: correct altChangedNum
//
class AltiSunView extends Ui.WatchFace {

	// watch vars

    var cx;
    var cy;
    var width; 
    var height;
    var pi2 = Math.PI / 2.0;

	// sunset sunrise vars 
	var utcOffset = new Time.Duration(-Sys.getClockTime().timeZoneOffset);
	var nextSunPhase = 0; // Julian time of next sun phase (rise OR set)
	var nowShowing = null; // enum: null OR sunrise OR sunset
	var sunTuple = null; // of class SunTuple
	var oldSunTuple = null; // from precedent day
	// delta sun time for current day
	var deltaMin = 0;
	// 
	var JD = new JulianDay();
	var SS = new SunsetSunrise();
	var lonW = null;//12.67d;
	var latN = null;//41.70d;
	var altitude = null;
	//
	var onSleep=null;
	var testShow = 0;
	var testMsg="";
	var settingChangedNum = -1;
	var locChangedNum = 0;
	var altChangedNum = 0;
	//
	var testMode=0;
	var VERSION="V:0.9.0";

	
	//
    function initialize() {
        WatchFace.initialize();
        getSettings();
    }

    //! Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));
        width = dc.getWidth();
        height = dc.getHeight();
		//Sys.println("## utcOffset: "+utcOffset.value());
		Sys.println("Version: " + VERSION);
        cx = width / 2;
        cy = height / 2;
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) {
        
        //dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
        //dc.fillRectangle(0,0,width,height);
              
        // Get the current time and format it correctly
        var timeFormat = "$1$:$2$";
        var clockTime = Sys.getClockTime();
        var hours = clockTime.hour;
        var min = clockTime.min;
        var sec = clockTime.sec;
        
        
        var settings = Sys.getDeviceSettings();
        var timeString = -1;
        if (settings.is24Hour){
        	timeString = Lang.format(timeFormat, [hours, min.format("%02d")]);
		}else{
			if (hours<13){
				timeString = Lang.format(timeFormat, [hours, min.format("%02d")]);
			}else{
				timeString = Lang.format(timeFormat, [hours-12, min.format("%02d")]);
			}
		}//Sys.println("## timeString:"+timeString);

		// lactivity info
		var actInfo = Act.getActivityInfo();
		//Sys.println("## actInfo:"+actInfo);

		// location
		var location = actInfo.currentLocation;
		//Sys.println("## actInfo location:"+location);
		
		
		// cicle info on some label
		if( SS.modulus(sec, 2).toLong()==0){
			testShow=testShow+1;
			if(testShow==3){
				testShow=0;
			}
		}
		
        // get altitude if present
		if(actInfo.altitude!=null){
			if (altitude != actInfo.altitude){
				altChangedNum+=1;
			}
			altitude=actInfo.altitude;
		}
		if(testMode==1){
			altitude=932;
		}
		// display altitude if present, cicle with delta sun time
        if(testShow==0 and altitude!=null){
        	var battLabelView = View.findDrawableById("BattLabel");
        	battLabelView.setText("Alt:"+ altitude.toLong());
        	//Sys.println("#### Alt:"+ altitude.toLong());
			battLabelView.setLocation(cx+76, cy-26);
        }else if(abs(deltaMin) > 0.01){
        	var battLabelView = View.findDrawableById("BattLabel");
        	if(deltaMin>=0){
        		battLabelView.setText("+"+deltaMin.format("%.2f")+" min");
        		Sys.println("#### "+deltaMin.format("%.2f")+" min");
        	}else{
        		battLabelView.setText(deltaMin.format("%.2f")+" min");
        		Sys.println("#### "+deltaMin.format("%.2f")+" min");
        	}
			battLabelView.setLocation(cx+76, cy-26);
        }
		
		// use the location if any, if not use the setting one
		if(location!=null){
			if(latN != location.toDegrees()[0]  || lonW != location.toDegrees()[1]){
				latN = location.toDegrees()[0];
				lonW = location.toDegrees()[1];
				locChangedNum=locChangedNum+1;
			}
			testMsg=settingChangedNum+"L-"+locChangedNum+"-"+altChangedNum;
		}else{
			testMsg=settingChangedNum+"S-"+locChangedNum+"-"+altChangedNum;
		}
		
		
		// use test label to display:
		//  test message 
        //  or lat lon if present
        var testLabelView = View.findDrawableById("TestLabel");
        if(testShow==0){
        	testLabelView.setText(testMsg);
        }else if (testShow==1){
        	testLabelView.setText("Lo:"+(lonW.format("%.2f")));
        }else{
        	testLabelView.setText("La:"+latN.format("%.2f"));
        }
        testLabelView.setLocation(cx-30, cy-66);
		
        
        // Get the current date
		var now = Time.now();
        var info = Calendar.info(now, Time.FORMAT_LONG);
        var dateStr = Lang.format("$1$", [info.day_of_week]);
        if(dateStr.length()>3){
        	dateStr=dateStr.substring(0,3);
        }
		dateStr = Lang.format("$1$ $2$", [dateStr, info.day]); 
        var monthStr;
        monthStr=Lang.format("$1$",[info.month]);
        if(monthStr.length()>4){
        	monthStr=monthStr.substring(0,4);
        }
        // Update the date label
        var dateLabelView = View.findDrawableById("DateLabel");
        dateLabelView.setText(dateStr);
        dateLabelView.setLocation(cx+44, cy-74);
        // month
        // Update the date month label
        var dateLabelMonthView = View.findDrawableById("DateLabelDay");
        dateLabelMonthView.setText(monthStr); 
        dateLabelMonthView.setLocation(cx+66, cy-52);

        // Update the time label
        var timeLabelView = View.findDrawableById("TimeLabel");
        timeLabelView.setText(timeString);
        timeLabelView.setLocation(cx, cy);
        
		// battery 
		var batt = (Sys.getSystemStats().battery).toDouble(); 
		
        // Update the steps/goal label
		var steps = ActMon.getInfo().steps;
		if(testMode==1){
			steps=6165;
		}
		var goal = ActMon.getInfo().stepGoal;
		
		// hearth rate
		var HRH=ActMon.getHeartRateHistory(1, true);
		var HRS=HRH.next();
		Sys.println("hearth: min="+HRH.getMin()+"; max="+HRH.getMax()+"; avrf="+HRS.heartRate);
		
		
		Sys.println("## steps:"+steps+"; goal:"+goal);
        var stepLabelView = View.findDrawableById("StepLabel");
        stepLabelView.setText(steps.format("%d")+"/"+goal.format("%d")+" steps");
		stepLabelView.setLocation(cx, cy+55);
		
        // Update the move label
		var move = (ActMon.getInfo().moveBarLevel).toLong();
		if(testMode==1){
			move=3;
		}
		//Sys.println("## move bar level:"+move);
		
		
        // Update the dist label
		var dist = -1;
		var kcal = (ActMon.getInfo().calories).toLong();
        var distLabelView = View.findDrawableById("DistLabel");
		if(testShow==0){
			if(settings.distanceUnits==Sys.UNIT_METRIC){
				dist = (ActMon.getInfo().distance).toDouble()/100000.0;
        		distLabelView.setText(dist.format("%.02f")+" Kms");
        	}else{
        		dist = (ActMon.getInfo().distance).toDouble()/160000.0;
        		distLabelView.setText(dist.format("%.02f")+" Mi");
        	}
        }else if(testShow==1){
        	distLabelView.setText(kcal+" Kcals");
        }
		distLabelView.setLocation(cx, cy+70);
        
        
        // draw sunset sunrise, recalculate once per day at 00:02
		if(nowShowing==null){
			Sys.println("## calculate sunset because nowShowing is null; utcOffset="+utcOffset);
			var julianDay = JD.evaluateJulianDay(utcOffset);
			onPosition(julianDay);
			drawSunInfo();
			nowShowing="Sunrise Sunset";
		}else{
			// update at 00:02
			if (hours==00 and min==01){
				Sys.println("## calculate sunset because of midnight; utcOffset="+utcOffset);
				oldSunTuple = sunTuple;
				var julianDay = JD.evaluateJulianDay(utcOffset);
				onPosition(julianDay);
				drawSunInfo();
				nowShowing="Sunrise Sunset";
			}
		}
		
		// left hand multiplicator
		var angleSteps = 0.0;
		var multSteps = 0.0;
		var multLabelView = View.findDrawableById("MultLabel");
		if(goal>0){
			//angleSteps = pi2 * (steps.toFloat()/goal.toFloat());
			angleSteps = pi2 * (steps.toFloat()/goal.toFloat());
			multSteps = angleSteps/pi2;
			Sys.println("");
			Sys.println("mult="+multSteps+"; mult.toLong="+multSteps.toLong()+"; angle="+angleSteps+"; mult bis:"+multSteps.format("%d"));
			if(multSteps.toLong()>0){
        		multLabelView.setText("X "+multSteps.format("%d"));
			}else{
				multLabelView.setText("");
			}
		}else{
			Sys.println("## goal=0");
			multLabelView.setText("");
		}
		multLabelView.setLocation(cx-52, cy-54); 

		var locY=0;
		var locX=0;
		//heart
		if(HRS.heartRate.toLong()>0 and HRS.heartRate.toLong()<255 or testMode==1){
			var heartIcon = View.findDrawableById("HeartRate");
			var heartLabel = View.findDrawableById("HeartLabel");
			locY = height/2 - 44;
			locX = width/2 + 22;
			heartIcon.setLocation(locX, locY);
			heartIcon.setBitmap(Rez.Drawables.HeartRateIcon);
			heartLabel.setLocation(locX+10, locY+18);
			if(testMode==1){
				heartLabel.setText("76");
			}else{
				heartLabel.setText(HRS.heartRate.format("%d"));
			}
		}
		
		
		// sun rise
		var sunIcon = View.findDrawableById("SunRise");
		var sunLabel = View.findDrawableById("SunLabel");
		locY = height/2 - 8;
		locX = width/2 + 60;
		sunIcon.setLocation(locX, locY);
		sunIcon.setBitmap(Rez.Drawables.SunsetIcon);
		sunLabel.setLocation(locX+14, locY+28);
		
		// sunt set
		var sunIcon2 = View.findDrawableById("SunSet");
		var sunLabel2 = View.findDrawableById("SunLabel2");
		locY = height/2 - 8;
		locX = width/2 - 84;
		sunIcon2.setLocation(locX, locY);
		sunIcon2.setBitmap(Rez.Drawables.SunriseIcon);
		sunLabel2.setLocation(locX+14, locY+28);
		
		// seconds
		if(!onSleep){
			var secLabel = View.findDrawableById("SecLabel");
			var locY = height/2 + 36;
			var locX = width/2 + 74;
			secLabel.setLocation(locX, locY);
			secLabel.setText(sec.toString());
		}else{
			var secLabel = View.findDrawableById("SecLabel");
			secLabel.setText("");
		}
		
		
		
		
		
		// other stuff
		if (settings.phoneConnected) {
			var blueIcon = View.findDrawableById("Blue");
			locY = height/2 + 40;
			locX = width/2  - 66;
			blueIcon.setLocation(locX, locY);
			blueIcon.setBitmap(Rez.Drawables.BluetoothIcon);
		} else{
			var blueIcon = View.findDrawableById("Blue");
			blueIcon.setLocation(-30, -30);
		}
		if (settings.notificationCount>0){
			var blueIcon = View.findDrawableById("Notification");
			locY = height/2 + 40;
			locX = width/2 - 86;
			blueIcon.setLocation(locX, locY);
			blueIcon.setBitmap(Rez.Drawables.NotificationIcon);
		}else{
			var blueIcon = View.findDrawableById("Notification");
			blueIcon.setLocation(-30, -30);
		}

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        
        // draw hands
		// the move hand 
		var dmove = ActMon.MOVE_BAR_LEVEL_MAX - ActMon.MOVE_BAR_LEVEL_MIN;
		if(move<3){
			dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
		}else{
			dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
		}
		//angle = pi2 * (move/dmove);
		if(move > 0){
			//drawCircleMarker(dc, 0, -pi2/5, move, 42, 2, true);
			drawCircleMarker(dc, Math.PI, pi2/5, move, 42, 2, true);
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
			drawCircleMarker(dc, Math.PI, pi2/5, move, 42, 3, false);
		}
        
		// the hand center circle
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		dc.fillCircle(cx, cy, 8);
		// the hand
		dc.fillCircle(cx, cy, 7);
		var handColor = Gfx.COLOR_GREEN;
		Sys.println("## angle bigger than pi2?:"+multSteps+"; pi2="+pi2);
		var angle2 = angleSteps;
		if(angleSteps>pi2){
			Sys.println("###### bigger than goal; angle="+angleSteps);
			angle2 = angleSteps - multSteps.toLong() * pi2;
			Sys.println("## bigger than goal; mult:"+multSteps+"; angle 2="+angle2);
			if(multSteps>=3){
				//dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
				handColor = Gfx.COLOR_RED;
			}else if(multSteps>=2){
				//dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
				handColor = Gfx.COLOR_ORANGE;
			}else if(multSteps>=1){
				//dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
				handColor = Gfx.COLOR_BLUE;
			}
		}else{
			Sys.println("###### NOT bigger than goal; angle="+angle2);
		}
		dc.setColor(handColor, Gfx.COLOR_TRANSPARENT);
		drawHand(dc, -pi2 + angle2, 78, 9, true);
		drawCircleMarker(dc, Math.PI, pi2/10, 10, 87, 2, true);
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		drawHand(dc, -pi2 + angle2, 78, 9, false);
		drawCircleMarker(dc, Math.PI, pi2/10, 10, 87, 3, false);
		// the center circle
		dc.setColor(handColor, Gfx.COLOR_TRANSPARENT);
		dc.fillCircle(cx, cy, 7);
		// the inner circle
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
		dc.fillCircle(cx, cy, 3);
		

		
		
        // draw bat icon
		var batw=24;
		var bath=8;
		var batp = (batw-2)*(batt/100.0);
		var top = 78;
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		dc.drawRectangle(cx-batw/2.0, cy-top, batw, bath);
		dc.fillRectangle(cx+batw/2.0, (cy-top)+3, 2, bath-6);
		//Sys.println("## batp:"+batp);
		if(batt > 40){
			dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
		}else if(batt > 20){
			dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
		}else{
			dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
			dc.drawRectangle(cx-batw/2.0, cy-top, batw, bath);
			dc.fillRectangle(cx+batw/2.0, (cy-top)+3, 3, bath-6);
		}
		dc.fillRectangle(cx-(batw/2)+1, (cy-top)+1, batp, bath-2);
		
        // second hands: disabled
		if(!onSleep && 1==2){
			dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
			drawSecondHand(dc, SS.degToRad(sec*6.0), 92, 4, true);
		}
    }
    
    
    //
	function drawCircleMarker(dc, angle, step, num, radius, size, filled){
        for (var i = 0; i <= num; i += 1) {
		    var cos = Math.cos(angle);
			var sin = Math.sin(angle);
            var x = (radius * cos) - (0 * sin) + cx;
            var y = (radius * sin) + (0 * cos) + cy;
			angle = angle + step;
			if(filled){
				dc.fillCircle(x, y, size);
			}else{
				dc.drawCircle(x, y, size);
			}
			
        }
	}


	//
	function drawSecondHand(dc, angle, radius, size, filled) {
		    var cos = Math.cos(angle);
			var sin = Math.sin(angle);
            var x = (radius * cos) - (0 * sin) + cx;
            var y = (radius * sin) + (0 * cos) + cy;
			if(filled){
				dc.fillCircle(x, y, size);
			}else{
				dc.drawCircle(x, y, size);
			}
	}


    
    //! Draw the watch hand
    //! @param dc Device Context to Draw
    //! @param angle Angle to draw the watch hand
    //! @param length Length of the watch hand
    //! @param width Width of the watch hand
    function drawHand(dc, angle, length, width, filled) {
        var coords = [ [-(width/2),0], [0, -length], [width/2, 0] ];
        var result = new [coords.size()];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        if(filled){
        	var result = new [coords.size()];
        	// Transform the coordinates
        	for (var i = 0; i < coords.size(); i += 1) {
            	var x = (coords[i][0] * cos) - (coords[i][1] * sin) + cx;
            	var y = (coords[i][0] * sin) + (coords[i][1] * cos) + cy;
            	//Sys.println("## result["+i+"]:"+x+" - "+y);
            	result[i] = [x, y];
        	}
        	dc.fillPolygon(result);
        }else{
        	var oldx=null;
        	var oldy=null;
        	for (var i = 0; i < coords.size(); i += 1) {
            	var x = (coords[i][0] * cos) - (coords[i][1] * sin) + cx;
            	var y = (coords[i][0] * sin) + (coords[i][1] * cos) + cy;
            	if(i==0){
            	}else{
            		dc.drawLine(oldx, oldy, x, y);
            	}
            	oldx=x;
            	oldy=y; 
        	}
        }
    }
    
    // mins to hh:mn
    function dayMinsToHM(dmn){
    	var h=(dmn/60.0).toLong();
    	var mn=(dmn - (h*60)).toLong();
    	var str = h.format("%02d")+":"+mn.format("%02d");
    	//Sys.println(" dayMinsToHM("+dmn+"): h:"+h+"; mn:"+mn+"; str:"+str);
    	return str;
    }
    
    // hh:mn to  mins
    function HMTodayMins(dmn){
    	var h=(dmn/60.0).toLong();
    	var mn=(dmn - (h*60)).toLong();
    	var str = h.format("%02d")+":"+mn.format("%02d");
    	//Sys.println(" dayMinsToHM("+dmn+"): h:"+h+"; mn:"+mn+"; str:"+str);
    	return str;
    }
    
    //
    function onPosition(jd) 
	{
		// test
		if(oldSunTuple != null){
			jd+=1;
		}
		
		Sys.println(" use long:"+lonW+"; latN:"+latN+"; jd="+jd+"; utcOffset=" + utcOffset.value());
		var sunrise = SS.calcSunriseUTC(jd, latN, -lonW); // in mins
		var sunset = SS.calcSunsetUTC(jd, latN, -lonW); // in mins
		sunset = sunset - utcOffset.value()/60.0;
		sunrise = sunrise - utcOffset.value()/60.0;
		
		sunTuple = new SunTuple();
		sunTuple.mSunrise = sunrise;
		sunTuple.mSunset = sunset;
		Sys.println(" sunTuple: sunrise:" + sunTuple.mSunrise+"; sunset:"+sunTuple.mSunset);
		Sys.println(" oldSunTuple:" +oldSunTuple +"; sunset:"+sunTuple);

		// diff from precedent day if any:
		if(oldSunTuple != null){
		    Sys.println(" calculate sunrise sunset");
			var matin =  (oldSunTuple.mSunrise - sunTuple.mSunrise);
			var soir = (sunTuple.mSunset - oldSunTuple.mSunset);
			//deltaMin = (oldSunTuple.mSunrise - sunTuple.mSunrise) + (sunTuple.mSunset - oldSunTuple.mSunset);
			deltaMin = matin + soir;
			//Sys.println(" sun deltaMin when no old 0:" + deltaMin);
			// convert decimal seconds in second
			var dsec = (deltaMin-deltaMin.toLong());
			//Sys.println(" dsec:" + dsec);
			dsec = dsec*60.0;
			//Sys.println(" dsec 1:" + dsec);
			deltaMin = deltaMin.toLong()+(dsec/100);
			//Sys.println(" sun deltaMin when old1 :" + deltaMin+"; matin:"+matin+"; soir:"+soir);
		}else{
			Sys.println(" calculate yesterday sunrise sunset");
			// calculate yesterday 
			jd = jd - 1.0;
			var sunriseYesterday = SS.calcSunriseUTC(jd, latN, -lonW); // in mins
			var sunsetYesterday = SS.calcSunsetUTC(jd, latN, -lonW); // in mins
			Sys.println(" calculate yesterday sunrise sunset; sunriseYesterday="+sunriseYesterday+"; sunsetYesterday="+sunsetYesterday);
			var matin =  (sunriseYesterday - sunTuple.mSunrise);
			var soir = (sunTuple.mSunset - sunsetYesterday);
			//deltaMin = (oldSunTuple.mSunrise - sunTuple.mSunrise) + (sunTuple.mSunset - oldSunTuple.mSunset);
			deltaMin = matin + soir;
			//Sys.println(" sun deltaMin when no old 0:" + deltaMin);
			// convert decimal seconds in second
			var dsec = (deltaMin-deltaMin.toLong());
			//Sys.println(" dsec:" + dsec);
			dsec = dsec*60.0;
			//Sys.println(" dsec 1:" + dsec);
			deltaMin = deltaMin.toLong()+(dsec/100);
			//Sys.println(" sun deltaMin when no old 1:" + deltaMin+"; matin:"+matin+"; soir:"+soir);
		}
		
	}
	
	// draw the sun icon and label
	function drawSunInfo()
	{
		var sunLabel = View.findDrawableById("SunLabel");          
		var glSunsetTimeString = dayMinsToHM(sunTuple.mSunset);         
			
		//sunLabel.setColor(Gfx.COLOR_LT_GRAY);
		sunLabel.setColor(Gfx.COLOR_WHITE);
		sunLabel.setText(glSunsetTimeString);
		
		//
		var sunLabel2 = View.findDrawableById("SunLabel2");     
		var glSunriseTimeString = dayMinsToHM(sunTuple.mSunrise);                 

		//sunLabel2.setColor(Gfx.COLOR_LT_GRAY);
		sunLabel2.setColor(Gfx.COLOR_WHITE);
		sunLabel2.setText(glSunriseTimeString);

		
	}
	
	// abs 
	function abs(a)
	{
		if (a<0){
			return -a;
		}else{
			return a;
		}
	}
	
	
	// called by app when setting changed
	function getSettings(){
		//Sys.println("@@@@@ getSettings");          
		settingChangedNum=settingChangedNum+1;
		readSettings();
	}
	
	// called by app when setting changed
	function readSettings(){
		lonW = App.getApp().getProperty("Longitude");
		latN = App.getApp().getProperty("Latitude");
		nowShowing=null;
	}

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    	onSleep=false;
    	Ui.requestUpdate();
    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    	onSleep=true;
    	Ui.requestUpdate();
    }

}
