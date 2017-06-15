using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class AltiSunApp extends App.AppBase {

	var view = null;
	
    function initialize() {
        AppBase.initialize();
    }


    //! Return the initial view of your application here
    function getInitialView() {
    	view = new AltiSunView();
        return [ view ];
    }


    //! New app settings have been received so trigger a UI update
    function onSettingsChanged() {
    	view.getSettings();
        Ui.requestUpdate();
    }
}