# $Id$

package EnsEMBL::Web::Component::Transcript::TranslationInfo;

use strict;

use EnsEMBL::Web::Document::HTML::TwoCol;

use base qw(EnsEMBL::Web::Component::Transcript);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self         = shift;
  my $object       = $self->object;
  my $table        = new EnsEMBL::Web::Document::HTML::TwoCol;
  my $transcript   = $object->Obj;
  my $translation  = $transcript->translation;

  $table->add_row('Ensembl version', $translation->stable_id.'.'.$translation->version);

  return $table->render;
}

1;
