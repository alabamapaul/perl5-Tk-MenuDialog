#!/usr/bin/perl -w
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##----------------------------------------------------------------------------
##        File: tk_menudialog_demo.pl
## Description: Demo of using the Tk::MenuDialog module
##----------------------------------------------------------------------------
use strict;
use warnings;
## Cannot use Find::Bin because script may be invoked as an
## argument to another script, so instead we use __FILE__
use File::Basename qw(dirname fileparse basename);
use File::Spec;
## Add script directory
use lib File::Spec->catdir(File::Spec->splitdir(dirname(__FILE__)));
## Add script directory/lib
use lib File::Spec->catdir(File::Spec->splitdir(dirname(__FILE__)), qq{lib});
## Add script directory/../lib
use lib File::Spec->catdir(File::Spec->splitdir(dirname(__FILE__)), qq{..}, qq{lib});
use Readonly;
use Tk::MenuDialog;
use Data::Dumper;

##---------------------------------------
## Hash used to initialize the form
##---------------------------------------
Readonly::Array my @MENU_ITEMS => (
  { label => qq{&Configure}, icon => qq{settings.png}, },
  { label => qq{Te&st},      icon => qq{test.png}, },
  { label => qq{&Run},       icon => qq{run.png},},
  );

##----------------------------------------------------------------------------
## Main code
##----------------------------------------------------------------------------
my $menu = Tk::MenuDialog->new(title => qq{Tk::MenuDialog Demo});

## Add this script's directory
$menu->add_icon_path(dirname(__FILE__));

## Add the menu items
foreach my $item (@MENU_ITEMS)
{
  $menu->add_item($item);
}

my $data = $menu->show;

print(
  qq{The following data was returned:\n},
  Data::Dumper->Dump([$data,], [qw( data)]),
  qq{\n},
  );

__END__