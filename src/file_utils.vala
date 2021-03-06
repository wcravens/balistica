/* Copyright 2013-2017 Steven Oliver <oliver.steven@gmail.com>
 *
 * This file is part of balística.
 *
 * balística is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * balística is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with balística.  If not, see <http://www.gnu.org/licenses/>.
 */

extern const string _SOURCE_ROOT_DIR ;

namespace Balistica{
   public const string SOURCE_ROOT_DIR = _SOURCE_ROOT_DIR ;

/**
 * Find the resource directory
 *
 * @return The base directory that the application's various resource files are stored.  If the
 * application is running from its installed directory, this will point to
 * $(BASEDIR)/share/<program name>.  If it's running from the build directory, this points to
 * that.
 *
 * From Geary by Yorba http://www.yorba.org/projects/geary/
 */
   private File get_resource_directory() {
	  return File.new_for_path (SOURCE_ROOT_DIR) ;
   }

/**
 * Creates a GTK builder given the filename of a UI file in the ui directory.
 *
 * @param ui_filename Filename, as string, of the UI file
 *
 * @return The newly created builder object
 *
 * From Geary by Yorba http://www.yorba.org/projects/geary/
 */
   public Gtk.Builder create_builder(string ui_filename) {
	  Gtk.Builder builder = new Gtk.Builder () ;
	  try {
		 builder.add_from_file (get_resource_directory ().get_child ("ui").get_child (ui_filename).get_path ()) ;
	  } catch ( GLib.Error error ){
		 warning ("Unable to create Gtk.Builder: %s".printf (error.message)) ;
	  }

	  return builder ;
   }

} // namespace
