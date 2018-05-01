/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

using Gtk;
using Gdk;
using Granite.Widgets;

public class NodeInspector : Stack {

  private Entry?      _name       = null;
  private ModeButton? _task       = null;
  private Switch?     _fold       = null;
  private TextView?   _note       = null;
  private DrawArea?   _da         = null;
  private Button?     _detach_btn = null;
  private string      _orig_note  = "";

  public NodeInspector( DrawArea da ) {

    _da = da;

    /* Set the transition duration information */
    transition_duration = 500;
    transition_type     = StackTransitionType.OVER_DOWN_UP;

    var empty_box = new Box( Orientation.VERTICAL, 10 );
    var empty_lbl = new Label( _( "<big>Select a node to view/edit information</big>" ) );
    var node_box  = new Box( Orientation.VERTICAL, 10 );

    empty_lbl.use_markup = true;
    empty_box.pack_start( empty_lbl, true, true );

    add_named( node_box,  "node" );
    add_named( empty_box, "empty" );

    /* Create the node widgets */
    create_name( node_box );
    create_task( node_box );
    create_fold( node_box );
    create_note( node_box );
    create_buttons( node_box );

    _da.node_changed.connect( node_changed );

    show_all();

  }

  /* Returns the width of this window */
  public int get_width() {
    return( 300 );
  }

  /* Creates the name entry */
  private void create_name( Box bbox ) {

    Box   box = new Box( Orientation.VERTICAL, 2 );
    Label lbl = new Label( _( "Name" ) );

    _name = new Entry();
    _name.activate.connect( name_changed );

    lbl.xalign = (float)0;

    box.pack_start( lbl,   true, false );
    box.pack_start( _name, true, false );

    bbox.pack_start( box, false, true );

  }

  /* Creates the task UI elements */
  private void create_task( Box bbox ) {

    var grid = new Grid();
    var lbl  = new Label( _( "Task" ) );

    lbl.xalign = (float)0;

    _task = new ModeButton();
    _task.has_tooltip = true;
    _task.append_icon( "minder-task-none-symbolic", IconSize.BUTTON );
    _task.append_icon( "minder-task-todo-symbolic", IconSize.BUTTON );
    _task.append_icon( "minder-task-done-symbolic", IconSize.BUTTON );
    _task.mode_changed.connect( task_changed );
    _task.query_tooltip.connect( task_tooltip );

    grid.column_homogeneous = true;
    grid.attach( lbl,   0, 0, 1, 1 );
    grid.attach( _task, 1, 0, 1, 1 );

    bbox.pack_start( grid, false, true );

  }

  /* Creates the fold UI elements */
  private void create_fold( Box bbox ) {

    var grid = new Grid();
    var lbl  = new Label( _( "Fold" ) );

    lbl.xalign = (float)0;

    _fold = new Switch();
    _fold.state_set.connect( fold_changed );

    grid.column_homogeneous = true;
    grid.attach( lbl,   0, 0, 1, 1 );
    grid.attach( _fold, 1, 0, 1, 1 );

    bbox.pack_start( grid, false, true );

  }

  /* Creates the note widget */
  private void create_note( Box bbox ) {

    Box   box = new Box( Orientation.VERTICAL, 0 );
    Label lbl = new Label( _( "Note" ) );

    lbl.xalign = (float)0;

    _note = new TextView();
    _note.set_wrap_mode( Gtk.WrapMode.WORD );
    _note.buffer.text = "";
    _note.buffer.changed.connect( note_changed );
    _note.focus_in_event.connect( note_focus_in );
    _note.focus_out_event.connect( note_focus_out );

    ScrolledWindow sw = new ScrolledWindow( null, null );
    sw.min_content_width  = 300;
    sw.min_content_height = 300;
    sw.add( _note );

    box.pack_start( lbl, false, false );
    box.pack_start( sw,  true,  true );

    bbox.pack_start( box, true, true );

  }

  /* Creates the node editing button grid and adds it to the popover */
  private void create_buttons( Box bbox ) {

    var grid = new Grid();
    grid.column_homogeneous = true;
    grid.column_spacing     = 10;

    /* Create the detach button */
    _detach_btn = new Button.from_icon_name( "minder-detach-symbolic", IconSize.SMALL_TOOLBAR );
    _detach_btn.set_tooltip_text( _( "Detach Node" ) );
    _detach_btn.clicked.connect( node_detach );

    /* Create the node deletion button */
    var del_btn = new Button.from_icon_name( "edit-delete-symbolic", IconSize.SMALL_TOOLBAR );
    del_btn.set_tooltip_text( _( "Delete Node" ) );
    del_btn.clicked.connect( node_delete );

    /* Add the buttons to the button grid */
    grid.attach( _detach_btn, 0, 0, 1, 1 );
    grid.attach( del_btn,     1, 0, 1, 1 );

    /* Add the button grid to the popover */
    bbox.pack_start( grid, false, true );

  }

  /*
   Called whenever the node name is changed within the inspector.
  */
  private void name_changed() {
    _da.change_current_name( _name.text );
  }

  /* Called whenever the task enable switch is changed within the inspector */
  private void task_changed( Widget w ) {
    Node current = _da.get_current_node();
    if( current != null ) {
      bool enable = false;
      bool done   = false;
      switch( _task.selected ) {
        case 0 :  enable = false;  done = false;  break;
        case 1 :  enable = true;   done = false;  break;
        case 2 :  enable = true;   done = true;   break;
      }
      _da.change_current_task( enable, done );
    }
  }

  /* Handles displaying a tooltip for the task modebuttons */
  private bool task_tooltip( int x, int y, bool keyboard, Tooltip tooltip ) {
    if( keyboard ) {
      return( false );
    }
    int button_width = _task.get_allocated_width() / 3;
    switch( x / button_width ) {
      case 0  :  tooltip.set_text( _( "Not a task" ) );       break;
      case 1  :  tooltip.set_text( _( "Unfinished task" ) );  break;
      case 2  :  tooltip.set_text( _( "Finished task" ) );    break;
      default :  return( false );
    }
    return( true );
  }

  /* Called whenever the fold switch is changed within the inspector */
  private bool fold_changed( bool state ) {
    _da.change_current_fold( state );
    return( false );
  }

  /*
   Called whenever the text widget is changed.  Updates the current node
   and redraws the canvas when needed.
  */
  private void note_changed() {
    _da.change_current_note( _note.buffer.text );
  }

  /* Saves the original version of the node's note so that we can */
  private bool note_focus_in( EventFocus e ) {
    _orig_note = _note.buffer.text;
    return( false );
  }

  /* When the note buffer loses focus, save the note change to the undo buffer */
  private bool note_focus_out( EventFocus e ) {
    Node? current = _da.get_current_node();
    if( (current != null) && (current.note != _orig_note) ) {
      _da.undo_buffer.add_item( new UndoNodeNote( _da, current, _orig_note ) );
    }
    return( false );
  }

  /* Detaches the current node and makes it a parent node */
  private void node_detach() {
    _da.detach();
    _detach_btn.set_sensitive( false );
  }

  private void node_delete() {
    Node? current = _da.get_current_node();
    if( current != null ) {
      current.delete( _da.get_layout() );
    }
  }

  /* Called whenever the user changes the current node in the canvas */
  private void node_changed() {

    Node? current = _da.get_current_node();

    if( current != null ) {
      _name.set_text( current.name );
      if( current.task_enabled() ) {
        _task.selected = current.task_done() ? 3 : 2;
      } else {
        _task.selected = 0;
      }
      _task.set_sensitive( current.is_leaf() );
      if( current.children().length > 0 ) {
        _fold.set_active( current.folded );
        _fold.set_sensitive( true );
      } else {
        _fold.set_active( false );
        _fold.set_sensitive( false );
      }
      _detach_btn.set_sensitive( current.parent != null );
      _note.buffer.text = current.note;
      set_visible_child_name( "node" );
    } else {
      set_visible_child_name( "empty" );
    }

  }

}
