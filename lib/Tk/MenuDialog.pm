package Tk::MenuDialog;
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
## NOTES:
##  * Before comitting this file to the repository, ensure Perl Critic can be
##    invoked at the HARSH [3] level with no errors
##****************************************************************************
=head1 NAME

Tk::MenuDialog - A  Moo based object oriented interface for creating and
display a dialog of buttons to be used as a menu using Tk

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  use Tk::MenuDialog;
  use File::Basename qw(dirname);

  my $menu = Tk::MenuDialog->new;

  ## Add the script's directory to the icon path
  ## when searching for icon files
  my $menu->add_icon_path(dirname(__FILE__));
  
  ## Add menu items to the menu
  $menu->add_item(
    label => qq{&Configure},
    icon  => qq{settings.png},
    );
  $menu->add_item(
    label => qq{&Run Tests},
    icon  => qq{run.png},
    );
    
  ## Allow operator to cancel the menu
  $menu->can_cancel(1);
  
  ## Display the menu and return hash reference of the selected item, 
  ## or UNDEF if canceled
  my $selection = $form->show;

=cut

##****************************************************************************
##****************************************************************************
use Moo;
## Moo enables strictures
## no critic (TestingAndDebugging::RequireUseStrict)
## no critic (TestingAndDebugging::RequireUseWarnings)
use Readonly;
use Carp qw(confess cluck);
use Tk;
use Tk::Photo;
use Data::Dumper;
use JSON;
use Try::Tiny;

## Version string
our $VERSION = qq{0.01};

##****************************************************************************
## Object attribute
##****************************************************************************

=head1 ATTRIBUTES

=cut

##****************************************************************************
##****************************************************************************

=head2 title

=over 2

Title of the menu

DEFAULT: ''

=back

=cut

##----------------------------------------------------------------------------
has title => (
  is      => qq{rw},
  default => qq{},
);

##****************************************************************************
##****************************************************************************

=head2 can_cancel

=over 2

Indicates if the operator can close the dialog without a selection

DEFAULT: 1

=back

=cut

##----------------------------------------------------------------------------
has can_cancel => (
  is      => qq{rw},
  default => 1,
);

##****************************************************************************

=head2 cancel_on_escape

=over 2

Boolean value indicating if pressing the Escape key should simulate closing
the window and canceling the dialog.

DEFAULT: 1

=back

=cut

##----------------------------------------------------------------------------
has cancel_on_escape => (
  is => qq{rw},
  default => 1,
);

##****************************************************************************
##****************************************************************************

=head2 items

=over 2

The items contained in this menu.

=back

=cut

##----------------------------------------------------------------------------
has items => (
  is => qq{rwp},
);

##****************************************************************************
##****************************************************************************

=head2 icon_path

=over 2

An array containing various paths to use when locating icon image files.

=back

=cut

##----------------------------------------------------------------------------
has icon_path => (
  is => qq{rwp},
);

##****************************************************************************

=head2 button_font

=over 2

Font to use for the buttons.

DEFAULT: 'times 10'

=back

=cut

##----------------------------------------------------------------------------
has button_font => (
  is => qq{rw},
  default => qq{times 10},
);

##****************************************************************************

=head2 min_width

=over 2

Minimum width of the dialog.

DEFAULT: 300

=back

=cut

##----------------------------------------------------------------------------
has min_width => (
  is => qq{rw},
  default => 300,
);

##****************************************************************************

=head2 min_height

=over 2

Minimum height of the dialog.

DEFAULT: 80

=back

=cut

##----------------------------------------------------------------------------
has min_height => (
  is => qq{rw},
  default => 80,
);

##****************************************************************************
## "Private" atributes
##***************************************************************************

## Holds reference to variable Tk watches for dialog completion 
has _watch_variable  => (
  is      => qq{rw},
);

##****************************************************************************
## Object Methods
##****************************************************************************

=head1 METHODS

=cut

=for Pod::Coverage BUILD
  This causes Test::Pod::Coverage to ignore the list of subs 
=cut
##----------------------------------------------------------------------------
##     @fn BUILD()
##  @brief Moo calls BUILD after the constructor is complete
## @return 
##   @note 
##----------------------------------------------------------------------------
sub BUILD
{
  my $self = shift;

  ## Create an empty list of items
  $self->_set_items([]);
  
  ## Create an empty list
  $self->_set_icon_path([]);
  
  return($self);
}

##****************************************************************************
##****************************************************************************

=head2 add_field($hash)

=over 2

=item B<Description>

Add a field to the form.

=item B<Parameters>

A hash reference with the following key / value pairs:
  label - Required paramater with 
  icon  - Optional filename of the icon to display
  icon_location - Optional location relative to button
                  text for the icon 
                  DEFAULT: "left"
See L<Tk::MenuDialog::Item> for more details

=item B<Return>

UNDEF on error, or the L<Tk::MenuDialog::Item> object created

=back

=cut

##----------------------------------------------------------------------------
sub add_item ## no critic (RequireArgUnpacking,ProhibitUnusedPrivateSubroutines)
{
  my $self  = shift;
  my $param = shift;

  ## Check for missing keys
  my @missing = ();
  foreach my $key (qw(label))
  {
    push(@missing, $key) unless(exists($params->{$key}));
  }
  if (scalar(@missing))
  {
    cluck(qq{Item missing the following reuired key(s): "}, 
      join(qq{", "}, @missing),
      qq{"}
      );
  }

  ## Get current item count
  my $index = scalar(@{$self->items});
  
  ## Create the new item
  my $item = {%{$param}, index => $index};
  
  ## Save the field in the object's fields attribute
  push(@{$self->items}, $item) if ($item);
      
  return($item);
}

##****************************************************************************
##****************************************************************************

=head2 show($parent)

=over 2

=item B<Description>

Show the dialog as a child of the given parent, or as a new MainWindow if
a parent is not specified.

The function will return if the users cancels the dialog or clicks a button

=item B<Parameters>

$parent - Parent window, if none is specified, a new MainWindow will be
created

=item B<Return>

UNDEF when canceled, or the hash reference associated with the button clicked.

=back

=cut

##----------------------------------------------------------------------------
sub show
{
  my $self   = shift;
  my $parent = shift;
  my $test   = shift;
  my $win;    ## Window widget
  my $result; ## Variable used to capture the result

  ## Create the window
  if ($parent)
  {
    ## Create as a TopLevel to the specified parent
    $win = $parent->TopLevel(-title => $self->title);
  }
  else
  {
    ## Create as a new MainWindow
    $win = MainWindow->new(-title => $self->title);
  }
  
  ## Hide the window
  $win->withdraw;
  
  ## Do not allow user to resize
  $win->resizable(0,0);

  ## Now use the grid geometry manager to layout everything
  my $grid_row = 0;
  
  my $first;
  ## Now add the itmes
  foreach my $item (@{$self->items})
  {
    ## See if the widget was created
    if (my $widget = $self->_build_button($item, $win))
    {
      ## Place the widget
      $widget->grid(
        -row        => $grid_row,
        -rowspan    => 1,
        -column     => 1,
        -columnspan => 1,
        -sticky     => qq{w},
      );
      
      ## Increment the row index
      $grid_row++;
      
      ## See if this is our first non-readonly field
      $first = $item if (!$first && !$item->enabled);
    }
  }
  
  ## Use an empty frame as a spacer 
  $win->Frame(-height => 5)->grid(-row => $grid_row++);
  
  $self->_watch_variable(\$result);
  
  ## Setup any keyboard bindings
  $self->_set_key_bindings($win);
  
  ## Calculate the geometry
  $self->_calc_geometry($win);

  ## Display the window
  $win->deiconify;
  
  ## Detect user closing the window
  $win->protocol('WM_DELETE_WINDOW',sub {$result = 0;});

  ## See if we are testing
  if ($test)
  {
    ## Make sure the string is the correct format
    if ($test =~ /TEST:\s+(-?\d+)/x)
    {
      ## < 0  means CANCEL
      ## >= 0 means select item indicated
      $test = $1;
      
      ## Set a callback to close the window
      $win->after(1500, sub {$result = $test;});
    }
  }

  ## Set the focus to the item
  $first->widget->focus() if ($first);

  ## Wait for variable to change
  $win->waitVariable(\$result);

  ## Hide the window
  $win->withdraw();

  ## See if we have a result
  if (defined($result))
  {
    ## See if the result is a valid index
    if (($result >= 0) && ($result < scalar(@{$self->items})))
    {
      ## Return the item object
      $result = $self->items->[$result];
    }
    else
    {
      ## Invalid index, so return UNDEF
      $result = undef;
    }
    ## Build the result
  }
  
  ## Destroy the window and all its widgets
  $win->destroy();
  
  return($result);
}

##----------------------------------------------------------------------------
##     @fn _build_button($item, $win)
##  @brief Build the button for the given item in the specified window
##  @param $item - HASH reference containing button information
##  @param $win - Parent object for the button
## @return 
##   @note 
##----------------------------------------------------------------------------
sub _build_button
{
  my $self   = shift;
  my $item   = shift;
  my $number = shift;
  my $win    = shift;
  my $widget;
  
  my $button_text = $self->button_label;
  my $underline   = index($button_text, qq{&});
  $button_text =~ s/\&//gx; ## Remove the &
  
  my $image;
  if (my $filename = $item->{icon})
  {
    unless (-f qq{$filename})
    {
      $filename = qq{};
      FIND_ICON_FILE_LOOP:
      foreach my $dir (@{$self->icon_path})
      {
        my $name = File::Spec->catfile(File::Spec->splitdir($dir), $item->{icon});
        if (-f qq{$name})
        {
          $filename = $name;
          last FIND_ICON_FILE_LOOP;
        }
      }
    }
    
    ## See if we have a filename
    if ($filename)
    {
      ## Load the filename
      $image = Tk::Photo->(-file => $filename)
    }
    else
    {
      cluck(
        qq{Could not locate icon "$item->{icon}"\nSearch Path:\n  "} .
        join(qq{"\n  }, (qq{.}, @{$self->icon_path})) . 
        qq{"\n}
        );
    }
  }

  ## Create the button
  if ($image)
  {
    $widget = $win->Button(
      -text      => $button_text,
      -font      => $self->button_font,
      -width     => length($button_text) + 2,
      -command   => sub {${$self->_watch_variable} = $number;},
      -underline => $underline,
      -image     => $image,
      -compound  => $item->{icon_location} // qq{left},
    );
  }
  else
  {
    $widget = $win->Button(
      -text      => $button_text,
      -font      => $self->button_font,
      -width     => length($button_text) + 2,
      -command   => sub {${$self->_watch_variable} = $number;},
      -underline => $underline,
    );
  }
  
  return($widget);
}

##----------------------------------------------------------------------------
##     @fn _determine_dimensions($parent)
##  @brief Determine the overal dimensions of the given widgets
##  @param $parent - Refernce to parent widget
## @return ($width, $height) - The width and height
##   @note 
##----------------------------------------------------------------------------
sub _determine_dimensions
{
  my $parent     = shift;
  my @children   = $parent->children;
  my $max_width  = 0;
  my $max_height = 0;

  foreach my $widget (@children)
  {
    my ($width, $height, $x_pos, $y_pos) = split(/[x\+]/x, $widget->geometry());
    $width += $x_pos;
    $height += $y_pos;
    
    $max_width = $width if ($width > $max_width);
    $max_height = $height if ($height > $max_height);
    
  }
  
  return($max_width, $max_height);
}

##----------------------------------------------------------------------------
##     @fn _calc_geometry($parent)
##  @brief Calculate window geometry to place the given window in the center
##         of the screen
##  @param $parent - Reference to the Main window widget
## @return void
##   @note 
##----------------------------------------------------------------------------
sub _calc_geometry
{
  my $self   = shift;
  my $parent = shift;

  return if (!defined($parent));
  return if (ref($parent) ne "MainWindow");
  
  ## Allow the geometry manager to update all sizes
  $parent->update();
  
  ## Determine the windows dimensions
  my ($width, $height)   = _determine_dimensions($parent);

  ## Determine the width and make sure it is at least $self->min_width
  $width = $self->min_width if ($width < $self->min_width);
  
  ## Determine the height and make sure it is at least $self->min_height
  $height = $self->min_height if ($height < $self->min_height);
  
  ## Calculate the X and Y to center on the screen
  my $pos_x = int(($parent->screenwidth - $width) / 2);
  my $pos_y = int(($parent->screenheight - $height) / 2);
  
  ## Update the geometry with the calculated values
  $parent->geometry("${width}x${height}+${pos_x}+${pos_y}");
  
  return;
}

##----------------------------------------------------------------------------
##     @fn _set_key_bindings($win)
##  @brief Set key bindings for the given window
##  @param $win - Window to use for binding keyboard events
## @return NONE
##   @note 
##----------------------------------------------------------------------------
sub _set_key_bindings
{
  my $self = shift;
  my $win  = shift;
  
  ## Now add the "hot key"
  my $number = 0;
  foreach my $item (@{$self->items})
  {
    ## Get the button text
    my $button_text = $self->label;
    
    ## Look for an ampersand in the label
    my $underline   = index($button_text, qq{&});
    
    ## See if an ampersand was found
    if ($underline >= 0)
    {
      ## Find the key within the string
      my $keycap = lc(substr($button_text, $underline, 1));
      
      ## Bind the key
      $win->bind(
        qq{<Alt-Key-$keycap>} => 
          sub
          {
            ${$self->_watch_variable} = $number;
          }
        );
    }
    
    $number++;
  }
  
  ## See if option set
  if ($self->cancel_on_escape)
  {
    $win->bind(qq{<Key-Escape>} => sub {${$self->_watch_variable} = -1;});
  }
  
  return;
}


##****************************************************************************
## Additional POD documentation
##****************************************************************************

=head1 AUTHOR

Paul Durden E<lt>alabamapaul AT gmail.comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2015 by Paul Durden.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    ## End of module
__END__
