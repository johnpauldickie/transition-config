package Mappings::Businesslink;

use strict;
use warnings;
use base 'Mappings::Rules';



sub actual_nginx_config {
    my $self = shift;
    
    my $config_or_error_type;
    my $suggested_link_type;
    my $config_line;
    my $suggested_link;
    my $archive_link;

    my $map_key = $self->get_map_key( $self->{'old_url_parts'} );
    if ( defined $map_key ) {
        if ( defined $self->{'duplicates'}{$map_key} ) {
            $config_or_error_type = 'duplicate_entry_error';
            $config_line = $self->{'old_url'} . "\n";
        }
        elsif ( '410' eq $self->{'status'} ) {
            # 410 Gone
            $config_or_error_type = 'gone_map';
            $config_line = "~${map_key} 410;\n";
            $suggested_link_type = 'suggested_link_map';
            $suggested_link = $self->get_suggested_link($map_key, 1);
            $archive_link = $self->get_archive_link($map_key);
        }
        elsif ( '301' eq $self->{'status'} ) {
            if ( length $self->{'new_url'}) {
                # 301 Moved Permanently
                $config_or_error_type   = 'redirect_map';
                $config_line = "~${map_key} $self->{'new_url'};\n";
            }
            else {
                $config_or_error_type = 'no_destination_error';
                $config_line = "$self->{'old_url'}\n";
            }
        }
        $self->{'duplicates'}{$map_key} = 1;
    }
    else {
        $config_or_error_type = 'no_map_key_error'; 
        $config_line = "$self->{'old_url'}\n";
    }

    return(
        $self->{'old_url_parts'}{'host'},
        $config_or_error_type,
        $config_line,
        $suggested_link_type,
        $suggested_link,
        $archive_link
    );

}
sub get_map_key {
    my $self         = shift;
    my $parts        = shift;
    
    my $path         = $parts->{'path'};
    my $query_string = $parts->{'query'};
    
    my $key;
    my $topic;
    my $item;
    
    if ( defined $query_string ) {
        $topic = $1
            if $query_string =~ m{topicId=(\d+)};
        $item = $1
            if $query_string =~ m{itemId=(\d+)};
    }
    
    if ( defined $topic && defined $item ) {
        if ( $path =~ m{^/bdotg/action/layer} ) {
            $key = "topicId=$topic";
        }
        else {
           $key = "itemId=$item";
        }
    }
    elsif ( defined $topic ) {
        $key = "topicId=$topic";
    }
    elsif ( defined $item ) {
        $key = "itemId=$item";
    }
    elsif ( defined $query_string && $query_string =~ m{page=(\w+)} ) {
        my $page = $1;
        $key = "page=$page";
    }
    
    return $key; 
}
sub get_suggested_link {
    my $self   = shift;
    my $lookup = shift;
    my $is_map = shift;
    
    return unless defined $self->{'suggested'} && length $self->{'suggested'};
    
    my $links;
    foreach my $line ( split /\n/, $self->{'suggested'} ) {
        $line = $self->escape_characters($line);
        
        my( $url, $text ) = split / /, $line, 2;
        $text = $self->presentable_url($url)
            unless defined $text;
        $links .= "<a href='${url}'>${text}</a>";
        
        # we only ever use the first link
        last;
    }
    
    return "\$query_suggested_link['${lookup}'] = \"${links}\";\n"
        if defined $is_map;
    return "\$location_suggested_link['${lookup}'] = \"${links}\";\n";
}

1;
