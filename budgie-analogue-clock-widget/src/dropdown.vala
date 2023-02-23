/*
 *  Budgie Raven Clock Dropdown
 *  Part of Budgie Analog Clock Widget
 *  Author: Sam Lane
 *  Copyright © 2023 Sam Lane
 *  Website=https://github.com/samlane-ma/
 *
 *  Copyright Budgie Desktop Developers

 *  This program is free software: you can redistribute it and/or modify it under
 *  the terms of the GNU General Public License as published by the Free Software
 *  Foundation, either version 3 of the License, or any later version. This
 *  program is distributed in the hope that it will be useful, but WITHOUT ANY
 *  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 *  A PARTICULAR PURPOSE. See the GNU General Public License for more details. You
 *  should have received a copy of the GNU General Public License along with this
 *  program.  If not, see <https://www.gnu.org/licenses/>.
 */

/*
 * RavenClockDropDown mimics the built-in Raven revealers, in an attempt to use
 * consistent margins and styling. It takes a Gtk.Widget header and a Gtk.Image
 * icon as parameters to display in the header box.
 * add_content is used to add the widget to dsplay when the revealer is expanded.
 */

 public class RavenClockDropDown : Gtk.Box {

	private Gtk.Revealer content_revealer;
	private Gtk.Box header_box;
	private Gtk.Box content;
	private Gtk.Widget? icon;
	private Gtk.Widget? header;

	public void add_content(Gtk.Widget widget) {
		content.add(widget);
		content.show_all();
	}

	public void remove_content(Gtk.Widget widget) {
		content.remove(widget);
	}

	private void style_icon() {
		icon.margin = 4;
		icon.margin_start = 12;
		icon.margin_end = 10;
	}

	public RavenClockDropDown (Gtk.Widget widget_header, Gtk.Widget widget_icon) {
		icon = widget_icon;
		header = widget_header;

		set_orientation(Gtk.Orientation.VERTICAL);
		set_spacing(0);
		header_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		header_box.get_style_context().add_class("raven-header");
		add(header_box);

		style_icon();

		header_box.add(icon);
		header_box.add(header);

		content = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		content.get_style_context().add_class("raven-background");
		content_revealer = new Gtk.Revealer();
		content_revealer.add(content);
		content_revealer.reveal_child = true;
		add(content_revealer);

		var header_reveal_button = new Gtk.Button.from_icon_name("pan-down-symbolic", Gtk.IconSize.MENU);
		header_reveal_button.get_style_context().add_class("flat");
		header_reveal_button.get_style_context().add_class("expander-button");
		header_reveal_button.margin = 4;
		header_reveal_button.valign = Gtk.Align.CENTER;
		header_reveal_button.clicked.connect(() => {
			content_revealer.reveal_child = !content_revealer.child_revealed;
			var image = (Gtk.Image?) header_reveal_button.get_image();
			if (content_revealer.reveal_child) {
				image.set_from_icon_name("pan-down-symbolic", Gtk.IconSize.MENU);
			} else {
				image.set_from_icon_name("pan-end-symbolic", Gtk.IconSize.MENU);
			}
		});
		header_box.pack_end(header_reveal_button, false, false, 0);
	}
}
