##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##----------------------------------------------------------------------------
##        File: 90-test_menu.t
## Description: Test the Tk::MenuDialog module
##----------------------------------------------------------------------------
use Test::More;
use Tk::MenuDialog;
use Readonly;


##---------------------------------------
## Hash used to initialize the menu
##---------------------------------------
Readonly::Scalar my $TEST_MENU => {
  title => qq{Tk::MenuDialog TEST},
  can_cancel => 0,
  button_spacing => 20,
  items => [
    {
      label => qq{Button &1},
    },
    {
      label => qq{Button &2},
    },
    {
      label => qq{Button &3},
    },
  ],
};

##----------------------------------------------------------------------------
## Main code
##----------------------------------------------------------------------------
my $button;
my $menu = Tk::MenuDialog->new->initialize($TEST_MENU);

## Stop testing if we didn't create the menu
BAIL_OUT('Could not create menu') unless ($menu);

## Check menu cancel
my $result = $menu->show(qq{TEST: -1});
ok(!defined($result), 'Menu cancel detected');

## Check menu selection
$button = 0;
$result = $menu->show(qq{TEST: $button});
ok(eq_hash($result, $TEST_MENU->{items}->[$button]), 'Menu selection detected');

diag(explain($result));



done_testing();