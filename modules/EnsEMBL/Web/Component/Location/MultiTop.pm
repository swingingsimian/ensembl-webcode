package EnsEMBL::Web::Component::Location::MultiTop;

use strict;

use EnsEMBL::Web::DBSQL::DBConnection;
use EnsEMBL::Web::Constants;

use base qw(EnsEMBL::Web::Component::Location);

sub _init {
  my $self = shift;
  $self->cacheable(1);
  $self->ajaxable(1);
  $self->has_image(1);
}

sub content {
  my $self = shift;
  my $hub  = $self->hub;
  
  return if $hub->param('show_panel') eq 'no';
  
  my $threshold       = 1e6 * ($hub->species_defs->ENSEMBL_GENOME_SIZE || 1); # get a slice corresponding to the region to be shown for Navigational Overview
  my $image_width     = $self->image_width;
  my $primary_species = $hub->species;
  my $slices          = $self->object->multi_locations;
  my $max             = scalar @$slices;
  my $i               = 1;
  my $gene_join_types = EnsEMBL::Web::Constants::GENE_JOIN_TYPES;
  my $compara_db      = new EnsEMBL::Web::DBSQL::DBConnection($primary_species)->_get_compara_database;
  my $join_genes      = $hub->param('opt_join_genes') eq 'on';
  my @images;
  
  foreach (@$slices) {
    my $highlight_gene    = $hub->param('g' . ($i - 1));
    my $slice             = $_->{'slice'};
    my $image_config      = $hub->get_imageconfig('MultiTop', "contigviewtop_$i", $_->{'species'});
    my $annotation_status = $image_config->get_node('annotation_status');
    
    if ($slice->length <= $threshold) {
      if ($_->{'length'} < $threshold) {
        $slice = $slice->adaptor->fetch_by_region($slice->coord_system->name, $slice->seq_region_name, 1, $slice->seq_region_length, 1);
      } else {
        my $c = int $slice->centrepoint;
        my $s = ($c - $threshold / 2) + 1;
           $s = 1 if $s < 1;
        my $e = $s + $threshold - 1;
        
        if ($e > $slice->seq_region_length) {
          $e = $slice->seq_region_length;
          $s = $e - $threshold - 1;
        }
        
        $slice = $slice->adaptor->fetch_by_region($slice->coord_system->name, $slice->seq_region_name, $s, $e, 1);
      }
    }
    
    $image_config->set_parameters({
      container_width => $slice->length,
      image_width     => $image_width,
      slice_number    => "$i|2",
      multi           => 1,
      compara         => $i == 1 ? 'primary' : $_->{'species'} eq $primary_species ? 'paralogue' : 'secondary',
      join_types      => $gene_join_types
    });
    
    if ($annotation_status) {
      $annotation_status->set('caption', '');
      $annotation_status->set('menu', 'no');
    };
    
    $image_config->get_node('ruler')->set('caption', $_->{'short_name'});
    $image_config->highlight($highlight_gene) if $highlight_gene;
    
    if ($join_genes) {
      $image_config->join_genes(map $_ >= 0 && $_ < $max ? $slices->[$_]->{'species'} : '', $i-2, $i);
      $slice->adaptor->db->set_adaptor('compara', $compara_db);
    }
    
    push @images, $slice, $image_config;
    
    $i++;
  }

  my $image = $self->new_image(\@images);
  
  return if $self->_export_image($image);
  
  $image->imagemap = 'yes';
  $image->set_button('drag', 'title' => 'Click or drag to centre display');
  $image->{'panel_number'} = 'top';
  
  return $image->render;
}

1;
