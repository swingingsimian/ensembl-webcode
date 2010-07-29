#$Id$
package EnsEMBL::Web::Data::Bio::Xref;

### NAME: EnsEMBL::Web::Data::Bio::Xref
### Base class - wrapper around a Bio::EnsEMBL::Xref API object 

### STATUS: Under Development
### Replacement for EnsEMBL::Web::Object::Xref

### DESCRIPTION:
### This module provides additional data-handling
### capabilities on top of those provided by the API

use strict;
use warnings;
no warnings qw(uninitialized);

use base qw(EnsEMBL::Web::Data::Bio);

sub convert_to_drawing_parameters {
### Converts a set of API objects into simple parameters 
### for use by drawing code and HTML components
### href parameter in $results is used for ZMenu drawing

  my $self = shift;
  my $data = $self->data_objects;
  my $results = [];
  my $hub = $self->hub;  
  my $ftype = $hub->param('ftype');

  foreach my $array (@$data) {    
    my $xref = shift @$array;
      
    foreach my $g (@$array) {      
      push @$results, {
        'label'    => $xref->db_display_name,
        'xref_id'  => [ $xref->primary_id ],
        'extname'  => $xref->display_id,  
        'start'    => $g->start,
        'end'      => $g->end,
        'region'   => $g->seq_region_name,
        'strand'   => $g->strand,
        'extra'    => [ $g->description, $xref->dbname ],
        'href'     => $hub->url({ type => 'Zmenu', action => 'Feature', function => 'Xref', ftype => $ftype, id => $xref->primary_id, r => undef }),
      };
    }
  }  

  return [$results, ['Description'], 'Xref'];
}

1;