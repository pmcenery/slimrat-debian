# slimrat - UploadedTo plugin
#
# Copyright (c) 2009 Přemek Vyhnal
#
# This file is part of slimrat, an open-source Perl scripted
# command line and GUI utility for downloading files from
# several download providers.
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# Authors:
#    Přemek Vyhnal <premysl.vyhnal gmail com>
#

#
# Configuration
#

# Package name
package UploadedTo;

# Extend Plugin
@ISA = qw(Plugin);

# Modules
use Toolbox;
use WWW::Mechanize;

# Custom packages
use Log;
use Toolbox;
use Configuration;

# Write nicely
use strict;
use warnings;


#
# Routines
#

# Constructor
sub new {
	my $self  = {};
	$self->{CONF} = $_[1];
	$self->{URL} = $_[2];
	$self->{MECH} = $_[3];
	bless($self);
	
	$self->{PRIMARY} = $self->fetch();
	
	return $self;
}

# Plugin name
sub get_name {
	return "UploadedTo";
}

# Filename
sub get_filename {
	my $self = shift;

	return $1.$2 if ($self->{PRIMARY}->decoded_content =~ m/Filename: \&nbsp;<\/td><td><b>\s*([^<]+?)\s+<\/b>.*Filetype: \&nbsp;<\/td><td>\s*([^<]*)\s*<\/td>/s);
}

# Filesize
sub get_filesize {
	my $self = shift;

	return readable2bytes($1) if ($self->{PRIMARY}->decoded_content =~ m/Filesize: \&nbsp;<\/td><td>\s*([^<]+?)\s*<\/td>/);
}

# Check if the link is alive
sub check {
	my $self = shift;
	
	return -1 if ($self->{MECH}->uri() =~ m#error_fileremoved#);
	return 0 if ($self->{MECH}->uri() =~ m#error#);
	return 1 if ($self->{PRIMARY}->decoded_content =~ m#Free Download#);
	return 0;
}

# Download data
sub get_data_loop  {
	# Input data
	my $self = shift;
	my $data_processor = shift;
	my $captcha_processor = shift;
	my $message_processor = shift;
	my $headers = shift;
	
	# Trafic exceeded
	if($self->{MECH}->content() =~ m#Or wait (\d+) minutes!#) {
		wait($1*60);
		$self->reload();
		return 1;
	}
	
	# Download URL
	elsif ($self->{MECH}->content() =~ m#<form name="download_form" method="post" action="(.+?)">#) {
		my $download = $1;
		my $req = HTTP::Request->new(POST => $download, $headers);
		$req->content_type('application/x-www-form-urlencoded');
		$req->content("download_submit=Free%20Download");
		return $self->{MECH}->request($req, $data_processor);
	}
	
	return;
}


# Amount of resources
Plugin::provide(1);

# Register the plugin
Plugin::register("^[^/]+//(up(loaded)?.to(/file)?|ul.to)/");

1;
