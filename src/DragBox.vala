[GtkTemplate (ui = "/org/gnome/balistica/drag.glade")]
public class Balistica.DragBox : Gtk.Box {

   // Struct used to hold calculation setup variables
   private struct calc_setup {
	  public int max ;
	  public int step ;
   }

   private LibBalistica.Solution lsln ;

   // Checkbox for atmospheric corrections
   [GtkChild]
   public Gtk.Button btnExportResults ;
   [GtkChild]
   public Gtk.Button btnResetDrag ;
   [GtkChild]
   public Gtk.Button btnSolveDrag ;
   [GtkChild]
   public Gtk.Button btnCalcPBR ;

   // Drag calculation results
   [GtkChild]
   public Gtk.TextView txtViewDragResults ;

   [GtkChild]
   public Gtk.Entry txtName ;
   [GtkChild]
   public Gtk.Entry txtDrag_coefficient ;
   [GtkChild]
   public Gtk.Entry txtProjectile_weight ;
   [GtkChild]
   public Gtk.Entry txtIntial_velocity ;
   [GtkChild]
   public Gtk.Entry txtZero_range ;
   [GtkChild]
   public Gtk.Entry txtSight_height ;
   [GtkChild]
   public Gtk.Entry txtShooting_angle ;
   [GtkChild]
   public Gtk.Entry txtWind_velocity ;
   [GtkChild]
   public Gtk.Entry txtWind_angle ;

   [GtkChild]
   public Gtk.Entry txtAltitude ;
   [GtkChild]
   public Gtk.Entry txtTemp ;
   [GtkChild]
   public Gtk.Entry txtBarPress ;
   [GtkChild]
   public Gtk.Entry txtRelaHumid ;

   [GtkChild]
   public Gtk.CheckButton ckbAtmosCorr ;

   // Radio buttons for drag functions
   [GtkChild]
   public Gtk.RadioButton rad_g1 ;
   [GtkChild]
   public Gtk.RadioButton rad_g2 ;
   [GtkChild]
   public Gtk.RadioButton rad_g5 ;
   [GtkChild]
   public Gtk.RadioButton rad_g6 ;
   [GtkChild]
   public Gtk.RadioButton rad_g7 ;
   [GtkChild]
   public Gtk.RadioButton rad_g8 ;

   // Radio buttons for calculation step size
   [GtkChild]
   public Gtk.RadioButton rad_s10 ;
   [GtkChild]
   public Gtk.RadioButton rad_s50 ;
   [GtkChild]
   public Gtk.RadioButton rad_s100 ;

   public DragBox () {
	  setDefaultAtmosphere () ;
   }

   /**
    * Toggle the atomospheric correction fields
    */
   [GtkCallback]
   public void atmo_toggled(Gtk.ToggleButton button) {
	  var enable = button.active ;
	  this.txtAltitude.set_sensitive (enable) ;
	  this.txtTemp.set_sensitive (enable) ;
	  this.txtBarPress.set_sensitive (enable) ;
	  this.txtRelaHumid.set_sensitive (enable) ;
   }

   /**
    * Reset the front end to prepare for a new drag calculation
    */
   [GtkCallback]
   public void btnResetDrag_clicked() {
	  this.txtName.set_text ("") ;

	  this.txtDrag_coefficient.set_text ("") ;
	  this.txtProjectile_weight.set_text ("") ;
	  this.txtIntial_velocity.set_text ("") ;
	  this.txtZero_range.set_text ("") ;
	  this.txtSight_height.set_text ("") ;
	  this.txtShooting_angle.set_text ("") ;
	  this.txtWind_velocity.set_text ("") ;
	  this.txtWind_angle.set_text ("") ;

	  setDefaultAtmosphere () ;

	  this.ckbAtmosCorr.set_active (false) ;
	  this.txtViewDragResults.buffer.text = "" ;
	  this.rad_g1.active = true ;
	  this.rad_s10.active = true ;

	  this.btnExportResults.set_sensitive (false) ;
	  this.btnCalcPBR.set_sensitive (false) ;
   }

   /**
    * Solve the drag function
    */
   [GtkCallback]
   public void btnSolveDrag_clicked() {
	  // Name used to store the calculation
	  string name = this.txtName.get_text () ;

	  // Ballistic cofficient
	  double bc = double.parse (this.txtDrag_coefficient.get_text ()) ;

	  // Initial velocity (ft/s)
	  double v = double.parse (this.txtIntial_velocity.get_text ()) ;

	  // Sight height over bore (inches)
	  double sh = double.parse (this.txtSight_height.get_text ()) ;

	  // Projectile weight (grains)
	  double w = double.parse (this.txtProjectile_weight.get_text ()) ;

	  // Shooting Angle (degrees)
	  double angle = double.parse (this.txtShooting_angle.get_text ()) ;

	  // Zero range of the rifle (yards)
	  double zero = double.parse (this.txtZero_range.get_text ()) ;

	  // Wind speed (mph)
	  double windspeed = double.parse (this.txtWind_velocity.get_text ()) ;

	  // Wind angle (0=headwind, 90=right-to-left, 180=tailwind, 270/-90=left-to-right)
	  double windangle = double.parse (this.txtWind_angle.get_text ()) ;

	  debug ("Calculation Name = %s", name) ;
	  debug ("Ballistic Coefficent: %f", bc) ;
	  debug ("Intial Velocity: %f", v) ;
	  debug ("Sight Height: %f", sh) ;
	  debug ("Projectile Weight: %f", w) ;
	  debug ("Angle: %f", angle) ;
	  debug ("Zero: %f", zero) ;
	  debug ("Wind speed: %f", windspeed) ;
	  debug ("Wind Angle: %f", windangle) ;

	  // It doesn't make sense for any of the following variables
	  // to be zero
	  if( bc <= 0 ){
		 ErrorHandler.get_default ().publish (new IOError.FAILED ("Drag Coefficient must be a positive value greater than 0")) ;
		 return ;
	  }

	  if( v <= 0 ){
		 ErrorHandler.get_default ().publish (new IOError.FAILED ("Initial Velocity must be a positive value greater than 0")) ;
		 return ;
	  }

	  if( sh <= 0 ){
		 ErrorHandler.get_default ().publish (new IOError.FAILED ("Sight Height over Bore must be a positive value greater than 0")) ;
		 return ;
	  }

	  if( w <= 0 ){
		 ErrorHandler.get_default ().publish (new IOError.FAILED ("Projectile Weight must be a positive value greater than 0")) ;
		 return ;
	  }

	  if( zero <= 0 ){
		 ErrorHandler.get_default ().publish (new IOError.FAILED ("Zero Range must be a positive value greater than 0")) ;
		 return ;
	  }

	  // Altitude
	  double alt = 0.0 ;
	  // Barometeric pressure
	  double bar = 29.53 ;
	  // Temerature
	  double tp = 59.0 ;
	  // Relative Humidity
	  double rh = 78.0 ;

	  if( this.ckbAtmosCorr.active ){
		 alt = double.parse (this.txtAltitude.get_text ()) ;
		 bar = double.parse (this.txtBarPress.get_text ()) ;
		 tp = double.parse (this.txtTemp.get_text ()) ;
		 rh = double.parse (this.txtRelaHumid.get_text ()) ;

		 debug ("Altitude: %f", alt) ;
		 debug ("Barometric Pressure: %f", bar) ;
		 debug ("Temperature: %f", tp) ;
		 debug ("Relative Humidty: %f", rh) ;
	  }

	  // Selected Drag Function
	  int df ;

	  // Which version of the drag do they want to calculate?
	  if( rad_g1.get_active ()){
		 df = 1 ;
	  } else if( rad_g2.get_active ()){
		 df = 2 ;
	  } else if( rad_g5.get_active ()){
		 df = 5 ;
	  } else if( rad_g6.get_active ()){
		 df = 6 ;
	  } else if( rad_g7.get_active ()){
		 df = 7 ;
	  } else {
		 df = 8 ;
	  }

	  // Make sure we're working with a new solution object
	  lsln = new LibBalistica.Solution () ;

	  // Calculate the solution and populate the object
	  lsln = Calculate.drag (bc, v, sh, w, angle, zero, windspeed, windangle, alt, bar, tp, rh, name, df) ;

	  if( lsln.getSolutionSize () == -1 ){
		 ErrorHandler.get_default ().publish (new IOError.FAILED ("Error creating solution results")) ;
		 return ;
	  } else {
		 txtViewDragResults.buffer.text = ("") ;
	  }

	  txtViewDragResults.buffer.text += ("Drag Coefficient: %.3f  Projectile Weight: %.2f grains\n").printf (lsln.getBc (), lsln.getWeight ()) ;
	  txtViewDragResults.buffer.text += ("Initial Velocity: %.2f ft/s  Zero Range: %.2f yards  Shooting Angle: %.2f degrees\n").printf (lsln.getMv (), lsln.getZerorange (), lsln.getAngle ()) ;
	  txtViewDragResults.buffer.text += ("Wind Velocity: %.2f mph  Wind Direction: %.2f degrees\n").printf (lsln.getWindspeed (), lsln.getWindangle ()) ;
	  txtViewDragResults.buffer.text += ("Altitude: %.2f ft  Barometer: %.2f in-Hg  Temperature: %.2f F  Relative Humidity: %.2f%%\n\n").printf (lsln.getAltitude (), lsln.getPressure (), lsln.getTemp (), lsln.getHumidity ()) ;

	  txtViewDragResults.buffer.text += "Range\tDropI\tDropM\tVelocity  Energy  Drift\tWindage\tTime\n" ;

	  double r, d, m, wi, wm, t, e ;

	  calc_setup setup = setupCalcResults () ;

	  for( int n = 0 ; n <= setup.max ; n = n + setup.step ){
		 r = lsln.getRange (n) ;
		 d = lsln.getDrop (n) ;
		 m = lsln.getMOA (n) ;
		 v = lsln.getVelocity (n) ;
		 wi = lsln.getWindage (n) ;
		 wm = lsln.getWindageMOA (n) ;
		 t = lsln.getTime (n) ;
		 e = lsln.getWeight () * v * v / 450436 ;

		 txtViewDragResults.buffer.text += ("%.0f\t%.2f\t%.2f\t%.0f      %.0f    %.2f\t%.2f\t%.2f\n").printf (r, d, m, v, e, wi, wm, t) ;
	  }

	  this.btnExportResults.set_sensitive (true) ;
	  this.btnCalcPBR.set_sensitive (true) ;
   }

   /**
    * Export the drag results to HTML
    */
   [GtkCallback]
   public void btnExportResults_clicked() {
	  if( this.lsln == null ){
		 ErrorHandler.get_default ().publish (new IOError.FAILED ("Cannot export an empty drag solution")) ;
		 return ;
	  }

	  // Create a save as dialog
	  Gtk.FileChooserDialog save_dialog = new Gtk.FileChooserDialog ("Save As",
																	 Application.main_window as Gtk.Window,
																	 Gtk.FileChooserAction.SAVE,
																	 "Cancel",
																	 Gtk.ResponseType.CANCEL,
																	 "Save",
																	 Gtk.ResponseType.ACCEPT) ;

	  save_dialog.select_multiple = false ;

	  // Filter to only HTML documents
	  Gtk.FileFilter filter = new Gtk.FileFilter () ;
	  filter.set_filter_name ("HTML") ;
	  filter.add_pattern ("*.html") ;
	  filter.add_mime_type ("text/html") ;
	  save_dialog.add_filter (filter) ;

	  GLib.File ? file ;
	  file = null ;
	  string filename = "" ;

	  // Confirm if the user wants to overwrite
	  save_dialog.set_do_overwrite_confirmation (true) ;
	  save_dialog.set_modal (true) ;

	  if( save_dialog.run () == Gtk.ResponseType.ACCEPT ){
		 filename = save_dialog.get_filename () ;
		 if( !filename.has_suffix (".html")){
			save_dialog.set_current_name (filename + ".html") ;
		 }
		 file = save_dialog.get_file () ;

		 // If the file already exists, delete it and write a new one
		 if( file.query_exists ()){
			try {
			   file.delete () ;
			} catch ( Error err ){
			   ErrorHandler.get_default ().publish (new IOError.FAILED ("Failed to overwrite existing file")) ;
			   return ;
			}
		 }

		 // Prevent null file errors
		 if( file != null ){
			try {
			   (save_dialog as Gtk.FileChooser).set_file (file) ;
			} catch ( GLib.Error err ){
			   ErrorHandler.get_default ().publish (new IOError.FAILED ("Error selecting file to save as")) ;
			   return ;
			}
		 }

		 // Write out the file
		 try {
			var file_stream = file.create (FileCreateFlags.NONE) ;
			var data_stream = new DataOutputStream (file_stream) ;
			data_stream.put_string ("<!DOCTYPE html>\n") ;
			data_stream.put_string (("<html>\n<head>\n<meta charset=\"UTF-8\">\n<title>%s</title>\n").printf (lsln.getName ())) ;
			data_stream.put_string ("<style type=\"text/css\"> table, th, td { border: 1px solid black; border-collapse: collapse; } th, td { padding: 10px; }</style>") ;
			data_stream.put_string ("</head>\n<body>\n") ;

			data_stream.put_string ("<table>\n") ;
			data_stream.put_string (("<tr>\n<td><b>Drag Coefficient:</b> %.2f</td>\n<td colspan=\"3\"><b>Projectile Weight:</b> %.2f</td>\n").printf (lsln.getBc (), lsln.getWeight ())) ;
			data_stream.put_string ("</tr>\n<tr>\n") ;
			data_stream.put_string (("<td><b>Initial Velocity:</b> %.2f ft/s</td>\n<td><b>Zero Range:</b> %.2f yards</td>\n<td colspan=\"2\"><b>Shooting Angle:</b> %.2f degress</td>\n").printf (lsln.getMv (), lsln.getZerorange (), lsln.getAngle ())) ;
			data_stream.put_string ("</tr>\n<tr>\n") ;
			data_stream.put_string (("<td><b>Wind Velocity:</b> %.2f mph</td>\n<td colspan=\"3\"><b>Wind Direction:</b> %.2f degress</td>\n").printf (lsln.getWindspeed (), lsln.getWindangle ())) ;
			data_stream.put_string ("</tr>\n<tr>\n") ;
			data_stream.put_string (("<td><b>Altitude:</b> %.2f ft</td>\n<td><b>Barometer:</b> %2f in-Hg</td>\n<td><b>Temperature:</b> %2f F</td>\n<td><b>Relative Humidity:</b> %.2F%%</td>\n").printf (lsln.getAltitude (), lsln.getPressure (), lsln.getTemp (), lsln.getHumidity ())) ;
			data_stream.put_string ("</table>\n") ;

			data_stream.put_string ("<table width=560>\n") ;
			data_stream.put_string ("<tr>\n") ;
			data_stream.put_string ("<th width=70 bgcolor=white align=center><b>Range (yards)</b></th>\n") ;
			data_stream.put_string ("<th width=70 bgcolor=white align=center><b>Drop (inches)</b></th>\n") ;
			data_stream.put_string ("<th width=70 bgcolor=white align=center><b>Drop (MOA)</b></th>\n") ;
			data_stream.put_string ("<th width=70 bgcolor=white align=center><b>Velocity (ft/s)</b></th>\n") ;
			data_stream.put_string ("<th width=70 bgcolor=white align=center><b>Energy (ft-lb)</b></th>\n") ;
			data_stream.put_string ("<th width=70 bgcolor=white align=center><b>Winddrift (inches)</b></th>\n") ;
			data_stream.put_string ("<th width=70 bgcolor=white align=center><b>Windage (MOA)</b></th>\n") ;
			data_stream.put_string ("<th width=70 bgcolor=white align=center><b>Time (s)</b></th>\n") ;
			data_stream.put_string ("</tr>\n") ;

			calc_setup setup = setupCalcResults () ;

			double r, d, m, wi, wm, t, e ;
			double v = double.parse (this.txtIntial_velocity.get_text ()) ;
			for( int n = 0 ; n <= setup.max ; n = n + setup.step ){
			   r = lsln.getRange (n) ;
			   d = lsln.getDrop (n) ;
			   m = lsln.getMOA (n) ;
			   v = lsln.getVelocity (n) ;
			   wi = lsln.getWindage (n) ;
			   wm = lsln.getWindageMOA (n) ;
			   t = lsln.getTime (n) ;
			   e = lsln.getWeight () * v * v / 450436 ;

			   data_stream.put_string ("<tr>\n") ;
			   data_stream.put_string (("<td>%.0f</td><td>%.2f</td><td>%.2f</td><td>%.0f</td><td>%.0f</td><td>%.2f</td><td>%.2f</td><td>%.2f</td>\n").printf (r, d, m, v, e, wi, wm, t)) ;
			   data_stream.put_string ("</tr>\n") ;
			}

			data_stream.put_string ("</table>\n") ;

			data_stream.put_string ("</body>\n</html>") ;
		 } catch ( GLib.Error err ){
			save_dialog.close () ;
			ErrorHandler.get_default ().publish (new IOError.FAILED ("Error creating HTML output")) ;

			return ;
		 }
	  }

	  // We're done with the save dialog
	  save_dialog.close () ;
   }

   /**
    * Set atmosphere settings back to the default
    */
   private void setDefaultAtmosphere() {
	  this.txtAltitude.set_text ("0") ;
	  this.txtTemp.set_text ("59.0") ;
	  this.txtBarPress.set_text ("29.53") ;
	  this.txtRelaHumid.set_text ("78.0") ;
   }

   /**
    * Setup an example calculation
    */
   private void setExampleCalculation() {
	  this.txtName.set_text ("308 Win Match, 168gr Sierra Match King") ;
	  this.txtDrag_coefficient.set_text ("0.465") ;
	  this.txtProjectile_weight.set_text ("168") ;
	  this.txtIntial_velocity.set_text ("2650") ;
	  this.txtZero_range.set_text ("200") ;
	  this.txtSight_height.set_text ("1.6") ;
	  this.txtShooting_angle.set_text ("0") ;
	  this.txtWind_velocity.set_text ("0") ;
	  this.txtWind_angle.set_text ("0") ;
   }

   /**
    * Return some basic setup values for each calculation
    */
   private calc_setup setupCalcResults() {
	  int max = lsln.getSolutionSize () ;
	  if( max > 1000 ){
		 max = 1000 ;
	  }

	  // The user can pick how many steps of the calculation they want to see
	  int step = 1 ;
	  if( this.rad_s10.get_active ()){
		 step = 10 ;
	  } else if( this.rad_s50.get_active ()){
		 step = 50 ;
	  } else if( this.rad_s100.get_active ()){
		 step = 100 ;
	  }

	  return calc_setup () {
				max = max, step = step
	  } ;
   }

}
