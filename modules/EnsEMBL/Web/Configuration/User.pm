package EnsEMBL::Web::Configuration::User;

### Configuration for all views based on the User object, including
### account management 

use strict;
use EnsEMBL::Web::Configuration;
use EnsEMBL::Web::Wizard::User;
use EnsEMBL::Web::Object::Data::User;
use EnsEMBL::Web::RegObj;

our @ISA = qw( EnsEMBL::Web::Configuration );

sub _add_javascript_libraries {
  ## 'private' method to load commonly-used JS libraries
  my $self = shift;
  $self->{page}->javascript->add_source( "/js/prototype.js" );  ## Javascript library 
  $self->{page}->javascript->add_source( "/js/accountview42.js" ); ## link magic
  $self->{page}->javascript->add_source( "/js/scriptaculous.js" ); ## Animations, drag and drop etc. 
}

sub context_menu {
  ### General context menu for all user management pages
  my $self = shift;
  my $obj = $self->{object};

  ## this menu clashes with mini one on non-account pages, so remove it
  $self->delete_block('ac_mini');

  ## Is the user logged in?
  my $user_id = $ENV{'ENSEMBL_USER_ID'};

  if ($user_id) {
    my $flag = 'user';
    $self->add_block( $flag, 'bulleted', "Your Vega" );

    $self->add_entry( $flag, 'text' => "Account summary",
                                    'href' => "/common/accountview" );
    $self->add_entry( $flag, 'text' => "Update details",
                                    'href' => "/common/update?id=$user_id" );
    $self->add_entry( $flag, 'text' => "Change password",
                                    'href' => "/common/set_password" );
    $self->add_entry( $flag, 'text' => "Log out",
                                    'href' => "javascript:logout_link()" );
  }
  else {
    my $flag = 'ac_full';
    $self->add_block( $flag, 'bulleted', "Your Ensembl" );

    $self->add_entry( $flag, 'text' => "Login",
                                  'href' => "javascript:login_link();" );
    $self->add_entry( $flag, 'text' => "Register",
                                  'href' => "/common/register" );
    $self->add_entry( $flag, 'text' => "Lost Password",
                                  'href' => "/common/lost_password" );
    $self->add_entry( $flag, 'text' => "About User Accounts",
                                    'href' => "/info/about/accounts.html" );
  }
}

sub access_denied {
  my $self   = shift;

  if (my $panel1 = $self->new_panel( 'Image',
    'code'    => "info$self->{flag}",
    'object'  => $self->{object},
    'caption' => 'Access Denied',
    ) ) {
    $panel1->add_components(qw(
        denied        EnsEMBL::Web::Component::User::denied
    ));

    ## add panel to page
    $self->add_panel( $panel1 );
  }
}

sub groupview {
  my $self   = shift;
  my $user = $self->{'object'};
  
  $self->_add_javascript_libraries;

  my $cgi = new CGI;

  if ($cgi->param('id')) {
    my $group = EnsEMBL::Web::Object::Group->new(( id => $cgi->param('id') ));

    if( my $details_panel = $self->new_panel( 'Image',
      'code'    => "group_details#",
      'caption' => "Overview for '" . $group->name . "'"
    )) {
      $details_panel->add_components(qw(
        group_details EnsEMBL::Web::Component::User::group_details
      ));
      $self->add_panel( $details_panel);
    }

    if( my $members_panel = $self->new_panel( 'Image',
      'code'    => "group_details#",
    )) {
      $members_panel->add_components(qw(
        group_users EnsEMBL::Web::Component::User::group_users
      ));
      $self->add_panel($members_panel);
    }

    if( my $members_panel = $self->new_panel( 'Image',
      'code'    => "group_details#",
    )) {
      $members_panel->add_components(qw(
        delete_group EnsEMBL::Web::Component::User::delete_group
      ));
      $self->add_panel($members_panel);
    }
  }
  else {
    if( my $members_panel = $self->new_panel( 'Image',
      'code'    => "group_details#",
    )) {
      $members_panel->add_components(qw(
        no_group EnsEMBL::Web::Component::User::no_group
      ));
      $self->add_panel($members_panel);
    }
  }

  $self->{page}->set_title('Manage group');
}

sub accountview {
  ### Dynamic view displaying information about a user account
  my $self   = shift;
  #my $user = $self->{object};
  #my $user = $ENSEMBL_WEB_REGISTRY->get_user;
  my $registry_user = $ENSEMBL_WEB_REGISTRY->get_user;
  my $user = EnsEMBL::Web::Object::Data::User->new({ id => $registry_user->id });

  $self->_add_javascript_libraries;

  if( my $details_panel = $self->new_panel( 'Image',
    'code'    => "details#",
    'user'    => $user,
    'caption' => 'Account home page for '. $user->name . " (" . $user->email . ")",
  )) {
    $details_panel->add_components(qw(
      user_details EnsEMBL::Web::Component::User::user_details
    ));
    $self->add_panel( $details_panel );
  }

  if( my $mixer_panel = $self->new_panel( 'Image',
    'code'    => "mixer#",
    'user'    => $user,
  )) {
    $mixer_panel->add_components(qw(
      settings_mixer EnsEMBL::Web::Component::User::settings_mixer
    ));
    $self->add_panel( $mixer_panel );
  }

  if( my $tabs_panel = $self->new_panel( 'Image',
    'code'    => "user_tabs#",
    'user'    => $user,
  )) {
    $tabs_panel->add_components(qw(
      user_tabs  EnsEMBL::Web::Component::User::user_tabs
    ));
    $self->add_panel( $tabs_panel );
  }

  if( my $prefs_panel = $self->new_panel( 'Image',
    'code'    => "user_prefs#",
    'user'    => $user,
  )) {
    $prefs_panel->add_components(qw(
      user_prefs  EnsEMBL::Web::Component::User::user_prefs
    ));
    $self->add_panel( $prefs_panel );
  }


  $self->{page}->set_title('Account summary: ' . $user->name);
}

sub user_menu {
  ### Context menu specific to user management pages
  my $self = shift;
  my $user = $self->{object};

  my $filter_id = 7;

  my $flag = 'news';

#  $self->add_block( $flag, 'bulleted', "News" );
#
#  $self->add_entry( $flag, 'text' => "Add News Filter",
#                           'href' => "/common/filter_news" );
#  $self->add_entry( $flag, 'text' => "Edit News Filter",
#                           'href' => "/common/filter_news?id=$filter_id" );
#  $self->add_entry( $flag, 'text' => "Ensembl mailing lists",
#                           'href' => "/info/about/contact.html#mailing_lists",
#                           'icon' => '/img/infoicon.gif' );

#  $flag = 'groups';
#
#  $self->add_block( $flag, 'bulleted', "Groups" );
#
#  $self->add_entry( $flag, 'text' => "Create new group",
#                           'href' => "/common/create_group" );
   
}

##-----------------------------------------------------------------------------
## Account management
##-----------------------------------------------------------------------------


sub user_login {
  my $self   = shift;
  my $object = $self->{'object'};
                                                                                
  ## the "user login" wizard uses 4 nodes: enter login details, validate password,
  ## set cookie and return to original page
  my $wizard = EnsEMBL::Web::Wizard::User->new($object);
  $wizard->add_nodes([qw(login validate set_cookie back_to_page)]);
  $wizard->default_node('login');

  $self->_add_javascript_libraries;
                                                                                
  ## chain the nodes together
  $wizard->add_outgoing_edges([
          ['login'=>'validate'],
          ['validate'=>'set_cookie'],
          ['set_cookie'=>'back_to_page'],
  ]);

  $self->add_wizard($wizard);
  $self->wizard_panel('Ensembl User Login');
}

sub user_logout {
  my $self   = shift;
  my $object = $self->{'object'};
  
  ## the "user logout" wizard consists of a single node!                                                                              
  my $wizard = EnsEMBL::Web::Wizard::User->new($object);
  $wizard->add_nodes([qw(logout)]);
  $wizard->default_node('logout');
  $self->add_wizard($wizard);
}

sub register {
  my $self = shift;
  my $version = "old";
  if ($version eq "old") {
    $self->hash_register;
  } else {
    $self->command_register;
  }
}

sub command_register {
  my $self = shift;
  my $user = EnsEMBL::Web::Wizard::Data::User(( object => $self->{'object'} ));
  my $wizard = EnsEMBL::Web::Wizard->new(( delegate => $user ));
  
}

sub hash_register {
  my $self   = shift;
  my $object = $self->{'object'};

  ## the user registration wizard uses 6 nodes: enter user data, look up user, preview data,
  ## save data, send account activation link and thanks
  my $wizard = EnsEMBL::Web::Wizard::User->new($object);
                                                    
  $wizard->add_nodes([qw(enter_details lookup_reg preview save_details send_link thanks_reg)]);
  $wizard->default_node('enter_details');

  ## chain the nodes together
  $wizard->add_outgoing_edges([
          ['enter_details'=>'lookup_reg'],
          ['lookup_reg'=>'preview'],
          ['preview'=>'save_details'],
          ['save_details'=>'send_link'],
          ['send_link'=>'thanks_reg'],
  ]);

  $self->add_wizard($wizard);
  $self->wizard_panel('Ensembl User Registration');
}

sub update_account {
  my $self   = shift;

  my $object = $self->{'object'};

  my $wizard = EnsEMBL::Web::Wizard::User->new($object);
                                                    
  ## the user registration wizard uses 3 nodes: enter data, preview data,
  ## and save data 
  $wizard->add_nodes([qw(enter_details preview save_details)]);
  $wizard->default_node('enter_details');

  $self->_add_javascript_libraries;
                                                                                
  ## chain the nodes together
  $wizard->add_outgoing_edges([
          ['enter_details'=>'preview'],
          ['preview'=>'save_details'],
  ]);

  $self->add_wizard($wizard);
  $self->wizard_panel('Update details');
}

sub set_password {
  my $self   = shift;
  my $object = $self->{'object'};

  ## the password wizard uses 5 nodes: validate, enter new password, compare passwords, 
  ## and save password
  my $wizard = EnsEMBL::Web::Wizard::User->new($object);
    
  $wizard->add_nodes([qw(validate set_cookie enter_password compare save_password)]);
  $wizard->default_node('enter_password');

  $self->_add_javascript_libraries;
                                                                                
  ## chain the nodes together
  $wizard->add_outgoing_edges([
          ['validate'=>'set_cookie'],
          ['set_cookie'=>'enter_password'],
          ['enter_password'=>'compare'],
          ['compare'=>'save_password'],
  ]);

  $self->add_wizard($wizard);
  $self->wizard_panel('Set Password');
}

sub lost_password {
  my $self   = shift;
  my $object = $self->{'object'};

  ## the lost password wizard uses 5 nodes: enter email, look up user, set password, 
  ## send email and acknowledge
  my $wizard = EnsEMBL::Web::Wizard::User->new($object);
    
  $wizard->add_nodes([qw(enter_email lookup_lost save_password send_link thanks_lost)]);
  $wizard->default_node('enter_email');

  ## chain the nodes together
  $wizard->add_outgoing_edges([
          ['enter_email'=>'lookup_lost'],
          ['lookup_lost'=>'save_password'],
          ['save_password'=>'send_link'],
          ['send_link'=>'thanks_lost'],
  ]);

  $self->add_wizard($wizard);
  $self->wizard_panel('Lost Password');
}

sub group_details {
  my $self   = shift;

  my $object = $self->{'object'};

  my $wizard = EnsEMBL::Web::Wizard::User->new($object);
                                                    
  ## the group wizard uses 3 nodes: edit group details, and save group details
  $wizard->add_nodes([qw(edit_group save_group)]);
  $wizard->default_node('groupview');

  $self->_add_javascript_libraries;
                                                                                
  ## chain the nodes together
  $wizard->add_outgoing_edges([
          ['edit_group'=>'save_group'],
  ]);

  $self->add_wizard($wizard);
  $self->wizard_panel('Group Details');
}

#sub start_a_group {
#  my $self = shift;
#  my $user = $self->{'object'};
#  my $wizard = EnsEMBL::Web::Wizard::User->new($user);
#  $wizard->add_nodes([ qw(add_group group_settings) ]);
#  $wizard->default_node('add_group');
#  $self->_add_javascript_libraries;
#  $wizard->add_outgoing_edges([
#    [ 'add_group' => 'group_settings' ],
#    [ 'group_settings' => 'save_group' ]
#  ]);
#  $self->add_wizard($wizard);
#  $self->wizard_panel('Start a new group');

sub start_a_group {
  my $self   = shift;

  my $object = $self->{'object'};

  my $wizard = EnsEMBL::Web::Wizard::User->new($object);
                                                    
  ## the group creation wizard uses 2 nodes: enter group details
  ## and save group
  $wizard->add_nodes([qw(enter_group save_group)]);
  $wizard->default_node('enter_group');

  $self->_add_javascript_libraries;
                                                                                
  ## chain the nodes together
  $wizard->add_outgoing_edges([
          ['enter_group'=>'save_group'],
  ]);

  $self->add_wizard($wizard);
  $self->wizard_panel('Start a Group');
}

sub join_a_group {
  my $self   = shift;

  my $object = $self->{'object'};

  my $wizard = EnsEMBL::Web::Wizard::User->new($object);
                                                    
  ## the group registration wizard uses 2 nodes: show list of available groups,
  ## and save membership 
  $wizard->add_nodes([qw(show_groups process_membership)]);
  $wizard->default_node('show_groups');

  $self->_add_javascript_libraries;
                                                                                
  ## chain the nodes together
  $wizard->add_outgoing_edges([
          ['show_groups'=>'process_membership'],
  ]);

  $self->add_wizard($wizard);
  $self->wizard_panel('Join a Group');
}

sub process_membership {
}

sub manage_members {
  my $self   = shift;

  my $object = $self->{'object'};

  my $wizard = EnsEMBL::Web::Wizard::User->new($object);
                                                    
  ## the manage members wizard uses 3 nodes: show list of members,
  ## activate member
  $wizard->add_nodes([qw(show_members activate_member)]);
  $wizard->default_node('show_members');

  $self->_add_javascript_libraries;
                                                                                
  ## chain the nodes together
  $wizard->add_outgoing_edges([
          ['show_members'=>'activate_member'],
  ]);

  $self->add_wizard($wizard);
  $self->wizard_panel('Manage Members');
}
##--------------------------------------------------------------------------------------------
## Account options
##--------------------------------------------------------------------------------------------

sub add_bookmark {
  my $self   = shift;
  my $object = $self->{'object'};

  ## the add bookmark wizard uses 3 nodes: set name of bookmark, save bookmark 
  ## and return to bookmarked URL
  my $wizard = EnsEMBL::Web::Wizard::User->new($object);
                                                    
  $self->_add_javascript_libraries;

  $wizard->add_nodes([qw(name_bookmark save_bookmark back_to_page)]);
  $wizard->default_node('back_to_page'); 

  ## chain the nodes together
  $wizard->add_outgoing_edges([
          ['name_bookmark'=>'save_bookmark'],
          ['save_bookmark'=>'back_to_page'],
  ]);

  $self->add_wizard($wizard);
  $self->wizard_panel('Bookmarks');
}

sub manage_bookmarks {
  my $self   = shift;
  my $object = $self->{'object'};

  ## the manage bookmark wizard uses 2 nodes: select bookmarks and delete bookmarks 
  my $wizard = EnsEMBL::Web::Wizard::User->new($object);
                                                    
  $self->_add_javascript_libraries;

  $wizard->add_nodes([qw(select_bookmarks delete_bookmarks)]);
  $wizard->default_node('select_bookmarks');

  ## chain the nodes together
  $wizard->add_outgoing_edges([
          ['select_bookmarks'=>'delete_bookmarks'],
  ]);

  $self->add_wizard($wizard);
  $self->wizard_panel('Bookmarks');
}

sub add_config {
  my $self   = shift;
  my $object = $self->{'object'};

  ## the add config wizard uses 4 nodes: set name of config, save config 
  ## and return to configured page
  my $wizard = EnsEMBL::Web::Wizard::User->new($object);
                                                    
  $self->_add_javascript_libraries;

  $wizard->add_nodes([qw(name_config save_config back_to_page)]);
  $wizard->default_node('back_to_page'); ## don't want user to access nodes without parameters!

  ## chain the nodes together
  $wizard->add_outgoing_edges([
          ['name_config'=>'save_config'],
          ['save_config'=>'back_to_page'],
  ]);

  $self->add_wizard($wizard);
  $self->wizard_panel('Saved Configurations');
}

sub manage_configs {
  my $self   = shift;
  my $object = $self->{'object'};

  ## the manage config wizard uses 2 nodes: select configs and delete configs 
  my $wizard = EnsEMBL::Web::Wizard::User->new($object);
                                                    
  $self->_add_javascript_libraries;

  $wizard->add_nodes([qw(select_configs delete_configs)]);
  $wizard->default_node('select_configs');

  ## chain the nodes together
  $wizard->add_outgoing_edges([
          ['select_configs'=>'delete_configs'],
  ]);

  $self->add_wizard($wizard);
  $self->wizard_panel('Saved Configurations');
}


1;


