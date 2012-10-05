
# Let the code begin...
package Bio::Tools::Run::Search::ncbiblastn;
use strict;
use Storable qw(dclone);

use vars qw( @ISA 
	     $ALGORITHM 
	     $VERSION 
	     $PARAMETER_OPTIONS );

use Bio::Tools::Run::Search::NCBIBlast;

@ISA = qw( Bio::Tools::Run::Search::NCBIBlast );

BEGIN{

  $ALGORITHM     = 'BLASTN';
  $VERSION       = 'Unknown';

  $PARAMETER_OPTIONS = dclone
    ( $Bio::Tools::Run::Search::NCBIBlast::PARAMETER_OPTIONS );

  delete( $PARAMETER_OPTIONS->{'-M'} );
}

#----------------------------------------------------------------------
sub algorithm   { return $ALGORITHM }
sub version     { return $VERSION }
sub parameter_options { return $PARAMETER_OPTIONS }

#----------------------------------------------------------------------
1;