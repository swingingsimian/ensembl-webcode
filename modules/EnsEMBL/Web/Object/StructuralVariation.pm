package EnsEMBL::Web::Object::StructuralVariation;

### NAME: EnsEMBL::Web::Object::StructuralVariation
### Wrapper around a Bio::EnsEMBL::StructuralVariation

### PLUGGABLE: Yes, using Proxy::Object

use strict;
use warnings;
no warnings "uninitialized";

use EnsEMBL::Web::Cache;

use base qw(EnsEMBL::Web::Object);

our $MEMD = new EnsEMBL::Web::Cache;

sub _filename {
  my $self = shift;
  my $name = sprintf '%s-structural-variation-%d-%s-%s',
    $self->species,
    $self->species_defs->ENSEMBL_VERSION,
    'structural variation',
    $self->name;
  $name =~ s/[^-\w\.]/_/g;
  return $name;
}

sub availability {
  my $self = shift;

  if (!$self->{'_availability'}) {
    my $availability = $self->_availability;
    my $obj = $self->Obj;

    if ($obj->isa('Bio::EnsEMBL::Variation::StructuralVariation')) {
      $availability->{'structural_variation'} = 1;
    }
    
    if (scalar @{$obj->get_all_SupportingStructuralVariants} != 0) {
      $availability->{'supporting_structural_variation'} = 1;
    }

    $self->{'_availability'} = $availability;
  }
  return $self->{'_availability'};
}


sub short_caption {
  my $self = shift;

  my $type = 'Structural variation';
  if ($self->class eq 'CNV_PROBE') {
     $type = 'CNV probe';
  }
  elsif($self->is_somatic) {
     $type = 'Somatic SV';
  }
  my $short_type = 'S. Var';
  return $type.' displays' unless shift eq 'global';

  my $label = $self->name;
  return length $label > 30 ? "$short_type: $label" : "$type: $label";
}


sub caption {
 my $self = shift;
 my $type = 'Structural variation';
 if ($self->class eq 'CNV_PROBE') {
   $type = 'Copy number variation probe';
 }
 elsif($self->is_somatic) {
   $type = 'Somatic structural variation';
 }
 my $caption = $type.': '.$self->name;

 return $caption;
}

sub name               { my $self = shift; return $self->Obj->variation_name;                                         }
sub class              { my $self = shift; return $self->Obj->var_class;                                              }
sub source             { my $self = shift; return $self->Obj->source;                                                 }
sub source_description { my $self = shift; return $self->Obj->source_description;                                     }
sub study              { my $self = shift; return $self->Obj->study;                                                  }
sub study_name         { my $self = shift; return (defined($self->study)) ? $self->study->name : undef;               }                
sub study_description  { my $self = shift; return (defined($self->study)) ? $self->study->description : undef;        } 
sub study_url          { my $self = shift; return (defined($self->study)) ? $self->study->url : undef;                }
sub external_reference { my $self = shift; return (defined($self->study)) ? $self->study->external_reference : undef; }
sub supporting_sv      { my $self = shift; return $self->Obj->get_all_SupportingStructuralVariants;                   }
sub is_somatic         { my $self = shift; return $self->Obj->is_somatic;                                             }

sub validation_status  { 
  my $self = shift; 
  my $states = $self->Obj->get_all_validation_states;
  if (scalar(@$states) and $states->[0]) {
    return join (',',@$states);
  }
  else { 
    return '';
  }
}    

# SSV associated colours
sub get_class_colour {
  my $self  = shift;
  my $class = shift;
  
  my %colour = (
    'copy_number_variation'         => '#000000',
    'insertion'                     => '#FFCC00',
    'copy_number_gain'              => '#0000FF', 
    'copy_number_loss'              => '#FF0000',
    'inversion'                     => '#9933FF', 
    'complex_structural_alteration' => '#99CCFF',
    'tandem_duplication'            => '#732E00',
    'mobile_element_insertion'      => '#FFCC00',
    'translocation'                 => '#C3A4FF',
  );
  
  my $c = $colour{$class};
  $c = '#B2B2B2' if (!$c);
  return $c;
}

sub get_structural_variation_annotations {
  my $self = shift;
  return $self->Obj->get_all_StructuralVariationAnnotations;
}


# Variation sets ##############################################################

sub get_variation_set_string {
  my $self = shift;
  my @vs = ();
  my $vari_set_adaptor = $self->hub->database('variation')->get_VariationSetAdaptor;
  my $sets = $vari_set_adaptor->fetch_all_by_StructuralVariation($self->Obj);

  my $toplevel_sets = $vari_set_adaptor->fetch_all_top_VariationSets;
  my $variation_string;
  my %sets_observed; 
  foreach (sort { $a->name cmp $b->name } @$sets){
    $sets_observed{$_->name}  =1 
  } 

  foreach my $top_set (@$toplevel_sets){
    next unless exists  $sets_observed{$top_set->name};
    $variation_string = $top_set->name ;
    my $sub_sets = $top_set->get_all_sub_VariationSets(1);
    my $sub_set_string = " (";
    foreach my $sub_set( sort { $a->name cmp $b->name } @$sub_sets ){ 
      next unless exists $sets_observed{$sub_set->name};
      $sub_set_string .= $sub_set->name .", ";  
    }
    if ($sub_set_string =~/\(\w/){
      $sub_set_string =~s/\,\s+$//;
      $sub_set_string .= ")";
      $variation_string .= $sub_set_string;
    }
    push(@vs,$variation_string);
  }
  return \@vs;
}

sub get_variation_sets {
  my $self = shift;
  my $vari_set_adaptor = $self->hub->database('variation')->get_VariationSetAdaptor;
  my $sets = $vari_set_adaptor->fetch_all_by_Variation($self->Obj); 
  return $sets;
}


# Structural Variation Feature ###########################################################

sub variation_feature_mapping { 

  ### Variation_mapping
  ### Example    : my @sv_features = $object->variation_feature_mapping
  ### Description: gets the Structural Variation features found on a structural variation object;
  ### Returns Arrayref of Bio::EnsEMBL::Variation::StructuralVariationFeatures

  my $self = shift;
 
  my %data;
  foreach my $sv_feature_obj (@{ $self->get_structural_variation_features }) { 
     my $svf_id = $sv_feature_obj->dbID;
     $data{$svf_id}{Type}             = $sv_feature_obj->slice->coord_system_name;
     $data{$svf_id}{Chr}              = $sv_feature_obj->seq_region_name;
     $data{$svf_id}{start}            = $sv_feature_obj->start;
     $data{$svf_id}{end}              = $sv_feature_obj->end;
     $data{$svf_id}{strand}           = $sv_feature_obj->strand;
     $data{$svf_id}{outer_start}      = $sv_feature_obj->outer_start;
     $data{$svf_id}{inner_start}      = $sv_feature_obj->inner_start;
     $data{$svf_id}{inner_end}        = $sv_feature_obj->inner_end;
     $data{$svf_id}{outer_end}        = $sv_feature_obj->outer_end;
     $data{$svf_id}{is_somatic}       = $sv_feature_obj->is_somatic;
     $data{$svf_id}{breakpoint_order} = $sv_feature_obj->breakpoint_order;
     $data{$svf_id}{transcript_vari}  = undef;
  }
  return \%data;
}

sub get_structural_variation_features {

  ### Structural_Variation_features
  ### Example    : my @sv_features = $object->get_structural_variation_features;
  ### Description: gets the Structural Variation features found  on a variation object;
  ### Returns Arrayref of Bio::EnsEMBL::Variation::StructuralVariationFeatures

   my $self = shift; 
   return $self->Obj ? $self->Obj->get_all_StructuralVariationFeatures : [];
}

sub not_unique_location {
  my $self = shift;
  unless ($self->hub->core_param('svf') ){
    my %mappings = %{ $self->variation_feature_mapping };
    my $count = scalar (keys %mappings);
    my $html;
    if ($count < 1) {
      $html = "<p>This feature has not been mapped.<p>";
    } elsif ($count > 1) { 
      $html = "<p>You must select a location from the panel above to see this information</p>";
    }
    return  $html;
  }
  return;
}


1;