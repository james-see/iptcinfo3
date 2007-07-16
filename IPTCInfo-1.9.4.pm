# IPTCInfo: extractor for IPTC metadata embedded in images
# Copyright (C) 2000-2004 Josh Carter <josh@multipart-mixed.com>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

package Image::IPTCInfo;
use IO::File;

use vars qw($VERSION);
$VERSION = '1.94';

#
# Global vars
#
use vars ('%datasets',		  # master list of dataset id's
		  '%datanames',       # reverse mapping (for saving)
		  '%listdatasets',	  # master list of repeating dataset id's
		  '%listdatanames',   # reverse
		  '$MAX_FILE_OFFSET', # maximum offset for blind scan
		  );

$MAX_FILE_OFFSET = 8192; # default blind scan depth

# Debug off for production use
my $debugMode = 0;
my $error;
	  
#####################################
# These names match the codes defined in ITPC's IIM record 2.
# This hash is for non-repeating data items; repeating ones
# are in %listdatasets below.
%datasets = (
#	0	=> 'record version',		# skip -- binary data
	5	=> 'object name',
	7	=> 'edit status',
	8	=> 'editorial update',
	10	=> 'urgency',
	12	=> 'subject reference',
	15	=> 'category',
#	20	=> 'supplemental category',	# in listdatasets (see below)
	22	=> 'fixture identifier',
#	25	=> 'keywords',				# in listdatasets
	26	=> 'content location code',
	27	=> 'content location name',
	30	=> 'release date',
	35	=> 'release time',
	37	=> 'expiration date',
	38	=> 'expiration time',
	40	=> 'special instructions',
	42	=> 'action advised',
	45	=> 'reference service',
	47	=> 'reference date',
	50	=> 'reference number',
	55	=> 'date created',
	60	=> 'time created',
	62	=> 'digital creation date',
	63	=> 'digital creation time',
	65	=> 'originating program',
	70	=> 'program version',
	75	=> 'object cycle',
	80	=> 'by-line',
	85	=> 'by-line title',
	90	=> 'city',
	92	=> 'sub-location',
	95	=> 'province/state',
	100	=> 'country/primary location code',
	101	=> 'country/primary location name',
	103	=> 'original transmission reference',
	105	=> 'headline',
	110	=> 'credit',
	115	=> 'source',
	116	=> 'copyright notice',
#	118	=> 'contact',            # in listdatasets
	120	=> 'caption/abstract',
	121	=> 'local caption',
	122	=> 'writer/editor',
#	125	=> 'rasterized caption', # unsupported (binary data)
	130	=> 'image type',
	131	=> 'image orientation',
	135	=> 'language identifier',
	200	=> 'custom1', # These are NOT STANDARD, but are used by
	201	=> 'custom2', # Fotostation. Use at your own risk. They're
	202	=> 'custom3', # here in case you need to store some special
	203	=> 'custom4', # stuff, but note that other programs won't 
	204	=> 'custom5', # recognize them and may blow them away if 
	205	=> 'custom6', # you open and re-save the file. (Except with
	206	=> 'custom7', # Fotostation, of course.)
	207	=> 'custom8',
	208	=> 'custom9',
	209	=> 'custom10',
	210	=> 'custom11',
	211	=> 'custom12',
	212	=> 'custom13',
	213	=> 'custom14',
	214	=> 'custom15',
	215	=> 'custom16',
	216	=> 'custom17',
	217	=> 'custom18',
	218	=> 'custom19',
	219	=> 'custom20',
	);

# this will get filled in if we save data back to file
%datanames = ();

%listdatasets = (
	20	=> 'supplemental category',
	25	=> 'keywords',
	118	=> 'contact',
	);

# this will get filled in if we save data back to file
%listdatanames = ();
	
#######################################################################
# New, Save, Destroy, Error
#######################################################################

#
# new
# 
# $info = new IPTCInfo('image filename goes here')
# 
# Returns IPTCInfo object filled with metadata from the given image 
# file. File on disk will be closed, and changes made to the IPTCInfo
# object will *not* be flushed back to disk.
#
sub new
{
	my ($pkg, $file, $force) = @_;

	my $input_is_handle = eval {$file->isa('IO::Handle')};
	if ($input_is_handle and not $file->isa('IO::Seekable')) {
		$error = "Handle must be seekable."; Log($error);
		return undef;
	}

	#
	# Open file and snarf data from it.
	#
	my $handle = $input_is_handle ? $file : IO::File->new($file);
	unless($handle)
	{
		$error = "Can't open file: $!"; Log($error);
		return undef;
	}

	binmode($handle);

	my $datafound = ScanToFirstIMMTag($handle);
	unless ($datafound || defined($force))
	{
		$error = "No IPTC data found."; Log($error);
		# don't close unless we opened it
		$handle->close() unless $input_is_handle;
		return undef;
	}

	my $self = bless
	{
		'_data'		=> {},	# empty hashes; wil be
		'_listdata'	=> {},	# filled in CollectIIMInfo
		'_handle'   => $handle,
	}, $pkg;

	$self->{_filename} = $file unless $input_is_handle;

	# Do the real snarfing here
	$self->CollectIIMInfo() if $datafound;
	
	$handle->close() unless $input_is_handle;
		
	return $self;
}

#
# create
#
# Like new, but forces an object to always be returned. This allows
# you to start adding stuff to files that don't have IPTC info and then
# save it.
#
sub create
{
	my ($pkg, $filename) = @_;

	return new($pkg, $filename, 'force');
}

#
# Save
#
# Saves JPEG with IPTC data back to the same file it came from.
#
sub Save
{
	my ($self, $options) = @_;

	return $self->SaveAs($self->{'_filename'}, $options);
}

#
# Save
#
# Saves JPEG with IPTC data to a given file name.
#
sub SaveAs
{
	my ($self, $newfile, $options) = @_;

	#
	# Open file and snarf data from it.
	#
	my $handle = $self->{_filename} ? IO::File->new($self->{_filename}) : $self->{_handle};
	unless($handle)
	{
		$error = "Can't open file: $!"; Log($error);
		return undef;
	}

	$handle->seek(0, 0);
	binmode($handle);

	unless (FileIsJPEG($handle))
	{
		$error = "Source file is not a JPEG; I can only save JPEGs. Sorry.";
		Log($error);
		return undef;
	}

	my $ret = JPEGCollectFileParts($handle, $options);

	if ($ret == 0)
	{
		Log("collectfileparts failed");
		return undef;
	}

	if ($self->{_filename}) {
		$handle->close();
		unless ($handle = IO::File->new($newfile, ">")) {
			$error = "Can't open output file: $!"; Log($error);
			return undef;
		}
		binmode($handle);
	} else {
		unless ($handle->truncate(0)) {
			$error = "Can't truncate, handle might be read-only"; Log($error);
			return undef;
		}
	}

	my ($start, $end, $adobe) = @$ret;

	if (defined($options) && defined($options->{'discardAdobeParts'}))
	{
		undef $adobe;
	}


	$handle->print($start);
	$handle->print($self->PhotoshopIIMBlock($adobe, $self->PackedIIMData()));
	$handle->print($end);

	$handle->close() if $self->{_filename};
		
	return 1;
}

#
# DESTROY
# 
# Called when object is destroyed. No action necessary in this case.
#
sub DESTROY
{
	# no action necessary
}

#
# Error
#
# Returns description of the last error.
#
sub Error
{
	return $error;
}

#######################################################################
# Attributes for clients
#######################################################################

#
# Attribute/SetAttribute
# 
# Returns/Changes value of a given data item.
#
sub Attribute
{
	my ($self, $attribute) = @_;

	return $self->{_data}->{$attribute};
}

sub SetAttribute
{
	my ($self, $attribute, $newval) = @_;

	$self->{_data}->{$attribute} = $newval;
}

sub ClearAttributes
{
	my $self = shift;

	$self->{_data} = {};
}

sub ClearAllData
{
	my $self = shift;

	$self->{_data} = {};
	$self->{_listdata} = {};
}

#
# Keywords/Clear/Add
# 
# Returns reference to a list of keywords/clears the keywords
# list/adds a keyword.
#
sub Keywords
{
	my $self = shift;
	return $self->{_listdata}->{'keywords'};
}

sub ClearKeywords
{
	my $self = shift;
	$self->{_listdata}->{'keywords'} = undef;
}

sub AddKeyword
{
	my ($self, $add) = @_;
	
	$self->AddListData('keywords', $add);
}

#
# SupplementalCategories/Clear/Add
# 
# Returns reference to a list of supplemental categories.
#
sub SupplementalCategories
{
	my $self = shift;
	return $self->{_listdata}->{'supplemental category'};
}

sub ClearSupplementalCategories
{
	my $self = shift;
	$self->{_listdata}->{'supplemental category'} = undef;
}

sub AddSupplementalCategories
{
	my ($self, $add) = @_;
	
	$self->AddListData('supplemental category', $add);
}

#
# Contacts/Clear/Add
# 
# Returns reference to a list of contactss/clears the contacts
# list/adds a contact.
#
sub Contacts
{
	my $self = shift;
	return $self->{_listdata}->{'contact'};
}

sub ClearContacts
{
	my $self = shift;
	$self->{_listdata}->{'contact'} = undef;
}

sub AddContact
{
	my ($self, $add) = @_;
	
	$self->AddListData('contact', $add);
}

sub AddListData
{
	my ($self, $list, $add) = @_;

	# did user pass in a list ref?
	if (ref($add) eq 'ARRAY')
	{
		# yes, add list contents
		push(@{$self->{_listdata}->{$list}}, @$add);
	}
	else
	{
		# no, just a literal item
		push(@{$self->{_listdata}->{$list}}, $add);
	}
}

#######################################################################
# XML, SQL export
#######################################################################

#
# ExportXML
# 
# $xml = $info->ExportXML('entity-name', \%extra-data,
#                         'optional output file name');
# 
# Exports XML containing all image metadata. Attribute names are
# translated into XML tags, making adjustments to spaces and slashes
# for compatibility. (Spaces become underbars, slashes become dashes.)
# Caller provides an entity name; all data will be contained within
# this entity. Caller optionally provides a reference to a hash of 
# extra data. This will be output into the XML, too. Keys must be 
# valid XML tag names. Optionally provide a filename, and the XML 
# will be dumped into there.
#
sub ExportXML
{
	my ($self, $basetag, $extraRef, $filename) = @_;
	my $out;
	
	$basetag = 'photo' unless length($basetag);
	
	$out .= "<$basetag>\n";

	# dump extra info first, if any
	foreach my $key (keys %$extraRef)
	{
		$out .= "\t<$key>" . $extraRef->{$key} . "</$key>\n";
	}
	
	# dump our stuff
	foreach my $key (keys %{$self->{_data}})
	{
		my $cleankey = $key;
		$cleankey =~ s/ /_/g;
		$cleankey =~ s/\//-/g;
		
		$out .= "\t<$cleankey>" . $self->{_data}->{$key} . "</$cleankey>\n";
	}

	if (defined ($self->Keywords()))
	{
		# print keywords
		$out .= "\t<keywords>\n";
		
		foreach my $keyword (@{$self->Keywords()})
		{
			$out .= "\t\t<keyword>$keyword</keyword>\n";
		}
		
		$out .= "\t</keywords>\n";
	}

	if (defined ($self->SupplementalCategories()))
	{
		# print supplemental categories
		$out .= "\t<supplemental_categories>\n";
		
		foreach my $category (@{$self->SupplementalCategories()})
		{
			$out .= "\t\t<supplemental_category>$category</supplemental_category>\n";
		}
		
		$out .= "\t</supplemental_categories>\n";
	}

	if (defined ($self->Contacts()))
	{
		# print contacts
		$out .= "\t<contacts>\n";
		
		foreach my $contact (@{$self->Contacts()})
		{
			$out .= "\t\t<contact>$contact</contact>\n";
		}
		
		$out .= "\t</contacts>\n";
	}

	# close base tag
	$out .= "</$basetag>\n";

	# export to file if caller asked for it.
	if (length($filename))
	{
		open(XMLOUT, ">$filename");
		print XMLOUT $out;
		close(XMLOUT);
	}
	
	return $out;
}

#
# ExportSQL
# 
# my %mappings = (
#   'IPTC dataset name here'    => 'your table column name here',
#   'caption/abstract'          => 'caption',
#   'city'                      => 'city',
#   'province/state'            => 'state); # etc etc etc.
# 
# $statement = $info->ExportSQL('mytable', \%mappings, \%extra-data);
#
# Returns a SQL statement to insert into your given table name 
# a set of values from the image. Caller passes in a reference to
# a hash which maps IPTC dataset names into column names for the
# database table. Optionally pass in a ref to a hash of extra data
# which will also be included in the insert statement. Keys in that
# hash must be valid column names.
#
sub ExportSQL
{
	my ($self, $tablename, $mappingsRef, $extraRef) = @_;
	my ($statement, $columns, $values);
	
	return undef if (($tablename eq undef) || ($mappingsRef eq undef));

	# start with extra data, if any
	foreach my $column (keys %$extraRef)
	{
		my $value = $extraRef->{$column};
		$value =~ s/'/''/g; # escape single quotes
		
		$columns .= $column . ", ";
		$values  .= "\'$value\', ";
	}
	
	# process our data
	foreach my $attribute (keys %$mappingsRef)
	{
		my $value = $self->Attribute($attribute);
		$value =~ s/'/''/g; # escape single quotes
		
		$columns .= $mappingsRef->{$attribute} . ", ";
		$values  .= "\'$value\', ";
	}
	
	# must trim the trailing ", " from both
	$columns =~ s/, $//;
	$values  =~ s/, $//;

	$statement = "INSERT INTO $tablename ($columns) VALUES ($values)";
	
	return $statement;
}

#######################################################################
# File parsing functions (private)
#######################################################################

#
# ScanToFirstIMMTag
#
# Scans to first IIM Record 2 tag in the file. The will either use
# smart scanning for JPEGs or blind scanning for other file types.
#
sub ScanToFirstIMMTag
{
	my $handle = shift @_;

	if (FileIsJPEG($handle))
	{
		Log("File is JPEG, proceeding with JPEGScan");
		return JPEGScan($handle);
	}
	else
	{
		Log("File not a JPEG, trying BlindScan");
		return BlindScan($handle);
	}
}

#
# FileIsJPEG
#
# Checks to see if this file is a JPEG/JFIF or not. Will reset the
# file position back to 0 after it's done in either case.
#
sub FileIsJPEG
{
	my $handle = shift @_;

	# reset to beginning just in case
	$handle->seek(0, 0);

	if ($debugMode)
	{
		Log("Opening 16 bytes of file:\n");
		my $dump;
		$handle->read($dump, 16);
		HexDump($dump);
		$handle->seek(0, 0);
	}

	# check start of file marker
	my ($ff, $soi);
	$handle->read($ff, 1) || goto notjpeg;
	$handle->read($soi, 1);
	
	goto notjpeg unless (ord($ff) == 0xff && ord($soi) == 0xd8);

	# now check for APP0 marker. I'll assume that anything with a SOI
	# followed by APP0 is "close enough" for our purposes. (We're not
	# dinking with image data, so anything following the JPEG tagging
	# system should work.)
	my ($app0, $len, $jpeg);
	$handle->read($ff, 1);
	$handle->read($app0, 1);

	goto notjpeg unless (ord($ff) == 0xff);

	# reset to beginning of file
	$handle->seek(0, 0);
	return 1;

  notjpeg:
	$handle->seek(0, 0);
	return 0;
}

#
# JPEGScan
#
# Assuming the file is a JPEG (see above), this will scan through the
# markers looking for the APP13 marker, where IPTC/IIM data should be
# found. While this isn't a formally defined standard, all programs
# have (supposedly) adopted Adobe's technique of putting the data in
# APP13.
#
sub JPEGScan
{
	my $handle = shift @_;

	# Skip past start of file marker
	my ($ff, $soi);
	$handle->read($ff, 1) || return 0;
	$handle->read($soi, 1);
	
	unless (ord($ff) == 0xff && ord($soi) == 0xd8)
	{
		$error = "JPEGScan: invalid start of file"; Log($error);
		return 0;
	}

	# Scan for the APP13 marker which will contain our IPTC info (I hope).

	my $marker = JPEGNextMarker($handle);

	while (ord($marker) != 0xed)
	{
		if (ord($marker) == 0)
		{ $error = "Marker scan failed"; Log($error); return 0; }

		if (ord($marker) == 0xd9)
		{ $error = "Marker scan hit end of image marker";
		  Log($error); return 0; }

		if (ord($marker) == 0xda)
		{ $error = "Marker scan hit start of image data";
		  Log($error); return 0; }

		if (JPEGSkipVariable($handle) == 0)
		{ $error = "JPEGSkipVariable failed";
		  Log($error); return 0; }

		$marker = JPEGNextMarker($handle);
	}

	# If were's here, we must have found the right marker. Now
	# BlindScan through the data.
	return BlindScan($handle, JPEGGetVariableLength($handle));
}

#
# JPEGNextMarker
#
# Scans to the start of the next valid-looking marker. Return value is
# the marker id.
#
sub JPEGNextMarker
{
	my $handle = shift @_;

	my $byte;

	# Find 0xff byte. We should already be on it.
	$handle->read($byte, 1) || return 0;
	while (ord($byte) != 0xff)
	{
		Log("JPEGNextMarker: warning: bogus stuff in JPEG file");
		$handle->read($byte, 1) || return 0;
	}

	# Now skip any extra 0xffs, which are valid padding.
	do
	{
		$handle->read($byte, 1) || return 0;
	} while (ord($byte) == 0xff);

	# $byte should now contain the marker id.
	Log("JPEGNextMarker: at marker " . unpack("H*", $byte));
	return $byte;
}

#
# JPEGGetVariableLength
#
# Gets length of current variable-length section. File position at
# start must be on the marker itself, e.g. immediately after call to
# JPEGNextMarker. File position is updated to just past the length
# field.
#
sub JPEGGetVariableLength
{
	my $handle = shift @_;

	# Get the marker parameter length count
	my $length;
	$handle->read($length, 2) || return 0;
		
	($length) = unpack("n", $length);

	Log("JPEG variable length: $length");

	# Length includes itself, so must be at least 2
	if ($length < 2)
	{
		Log("JPEGGetVariableLength: erroneous JPEG marker length");
		return 0;
	}
	$length -= 2;

	return $length;
}

#
# JPEGSkipVariable
#
# Skips variable-length section of JPEG block. Should always be called
# between calls to JPEGNextMarker to ensure JPEGNextMarker is at the
# start of data it can properly parse.
#
sub JPEGSkipVariable
{
	my $handle = shift;
	my $rSave = shift;

	my $length = JPEGGetVariableLength($handle);
	return if ($length == 0);

	# Skip remaining bytes
	my $temp;
	if (defined($rSave) || $debugMode)
	{
		unless ($handle->read($temp, $length))
		{
			Log("JPEGSkipVariable: read failed while skipping var data");
			return 0;
		}

		# prints out a heck of a lot of stuff
		# HexDump($temp);
	}
	else
	{
		# Just seek
		unless($handle->seek($length, 1))
		{
			Log("JPEGSkipVariable: read failed while skipping var data");
			return 0;
		}
	}

	$$rSave = $temp if defined($rSave);

	return 1;
}

#
# BlindScan
#
# Scans blindly to first IIM Record 2 tag in the file. This method may
# or may not work on any arbitrary file type, but it doesn't hurt to
# check. We expect to see this tag within the first 8k of data. (This
# limit may need to be changed or eliminated depending on how other
# programs choose to store IIM.)
#
sub BlindScan
{
	my $handle = shift;
    my $maxoff = shift() || $MAX_FILE_OFFSET;
    
	Log("BlindScan: starting scan, max length $maxoff");
	
	# start digging
	my $offset = 0;
	while ($offset <= $maxoff)
	{
		my $temp;
		
		unless ($handle->read($temp, 1))
		{
			Log("BlindScan: hit EOF while scanning");
			return 0;
		}

		# look for tag identifier 0x1c
		if (ord($temp) == 0x1c)
		{
			# if we found that, look for record 2, dataset 0
			# (record version number)
			my ($record, $dataset);
			$handle->read($record, 1);
			$handle->read($dataset, 1);
			
			if (ord($record) == 2)
			{
				# found it. seek to start of this tag and return.
				Log("BlindScan: found IIM start at offset $offset");
				$handle->seek(-3, 1); # seek rel to current position
				return $offset;
			}
			else
			{
				# didn't find it. back up 2 to make up for
				# those reads above.
				$handle->seek(-2, 1); # seek rel to current position
			}
		}
		
		# no tag, keep scanning
		$offset++;
	}
	
	return 0;
}

#
# CollectIIMInfo
#
# Assuming file is seeked to start of IIM data (using above), this
# reads all the data into our object's hashes
#
sub CollectIIMInfo
{
	my $self = shift;
	
	my $handle = $self->{_handle};
	
	# NOTE: file should already be at the start of the first
	# IPTC code: record 2, dataset 0.
	
	while (1)
	{
		my $header;
		return unless $handle->read($header, 5);
		
		($tag, $record, $dataset, $length) = unpack("CCCn", $header);

		# bail if we're past end of IIM record 2 data
		return unless ($tag == 0x1c) && ($record == 2);
		
		# print "tag     : " . $tag . "\n";
		# print "record  : " . $record . "\n";
		# print "dataset : " . $dataset . "\n";
		# print "length  : " . $length  . "\n";
	
		my $value;
		$handle->read($value, $length);
		
		# try to extract first into _listdata (keywords, categories)
		# and, if unsuccessful, into _data. Tags which are not in the
		# current IIM spec (version 4) are currently discarded.
		if (exists $listdatasets{$dataset})
		{
			my $dataname = $listdatasets{$dataset};
			my $listref  = $listdata{$dataname};
			
			push(@{$self->{_listdata}->{$dataname}}, $value);
		}
		elsif (exists $datasets{$dataset})
		{
			my $dataname = $datasets{$dataset};
	
			$self->{_data}->{$dataname} = $value;
		}
		# else discard
	}
}

#######################################################################
# File Saving
#######################################################################

#
# JPEGCollectFileParts
#
# Collects all pieces of the file except for the IPTC info that we'll
# replace when saving. Returns the stuff before the info, stuff after,
# and the contents of the Adobe Resource Block that the IPTC data goes
# in. Returns undef if a file parsing error occured.
#
sub JPEGCollectFileParts
{
	my $handle = shift;
	my ($options) = @_;
	my ($start, $end, $adobeParts);
	my $discardAppParts = 0;

	if (defined($options) && defined($options->{'discardAppParts'}))
	{ $discardAppParts = 1; }

	# Start at beginning of file
	$handle->seek(0, 0);

	# Skip past start of file marker
	my ($ff, $soi);
	$handle->read($ff, 1) || return 0;
	$handle->read($soi, 1);
	
	unless (ord($ff) == 0xff && ord($soi) == 0xd8)
	{
		$error = "JPEGScan: invalid start of file"; Log($error);
		return 0;
	}

	#
	# Begin building start of file
	#
	$start .= pack("CC", 0xff, 0xd8);

	# Get first marker in file. This will be APP0 for JFIF or APP1 for
	# EXIF.
	my $marker = JPEGNextMarker($handle);

	my $app0data;
	if (JPEGSkipVariable($handle, \$app0data) == 0)
	{ $error = "JPEGSkipVariable failed";
	  Log($error); return 0; }

	if (ord($marker) == 0xe0 || !$discardAppParts)
	{
		# Always include APP0 marker at start if it's present.
		$start .= pack("CC", 0xff, ord($marker));
		# Remember that the length must include itself (2 bytes)
		$start .= pack("n", length($app0data) + 2);
		$start .= $app0data;
	}
	else
	{
		# Manually insert APP0 if we're trashing application parts, since
		# all JFIF format images should start with the version block.
		$start .= pack("CC", 0xff, 0xe0);
		$start .= pack("n", 16);    # length (including these 2 bytes)
		$start .= "JFIF";           # format
		$start .= pack("CC", 1, 2); # call it version 1.2 (current JFIF)
		$start .= pack(C8, 0);      # zero everything else
	}

	#
	# Now scan through all markers in file until we hit image data or
	# IPTC stuff.
	#
	$marker = JPEGNextMarker($handle);

	while (1)
	{
		if (ord($marker) == 0)
		{ $error = "Marker scan failed"; Log($error); return 0; }

		# Check for end of image
		if (ord($marker) == 0xd9)
		{
			Log("JPEGCollectFileParts: saw end of image marker");
			$end .= pack("CC", 0xff, ord($marker));
			goto doneScanning;
		}

		# Check for start of compressed data
		if (ord($marker) == 0xda)
		{
			Log("JPEGCollectFileParts: saw start of compressed data");
			$end .= pack("CC", 0xff, ord($marker));
			goto doneScanning;
		}

		my $partdata;
		if (JPEGSkipVariable($handle, \$partdata) == 0)
		{ $error = "JPEGSkipVariable failed";
		  Log($error); return 0; }

		# Take all parts aside from APP13, which we'll replace
		# ourselves.
		if ($discardAppParts && ord($marker) >= 0xe0 && ord($marker) <= 0xef)
		{
			# Skip all application markers, including Adobe parts
			undef $adobeParts;
		}
		elsif (ord($marker) == 0xed)
		{
			# Collect the adobe stuff from part 13
			$adobeParts = CollectAdobeParts($partdata);
			goto doneScanning;
		}
		else
		{
			# Append all other parts to start section
			$start .= pack("CC", 0xff, ord($marker));
			$start .= pack("n", length($partdata) + 2);
			$start .= $partdata;
		}

		$marker = JPEGNextMarker($handle);
	}

  doneScanning:

	#
	# Append rest of file to $end
	#
	my $buffer;

	while ($handle->read($buffer, 16384))
	{
		$end .= $buffer;
	}

	return [$start, $end, $adobeParts];
}

#
# CollectAdobeParts
#
# Part APP13 contains yet another markup format, one defined by Adobe.
# See "File Formats Specification" in the Photoshop SDK (avail from
# www.adobe.com). We must take everything but the IPTC data so that
# way we can write the file back without losing everything else
# Photoshop stuffed into the APP13 block.
#
sub CollectAdobeParts
{
	my ($data) = @_;
	my $length = length($data);
	my $offset = 0;
	my $out = '';

	# Skip preamble
	$offset = length('Photoshop 3.0 ');

	# Process everything
	while ($offset < $length)
	{
		# Get OSType and ID
		my ($ostype, $id1, $id2) = unpack("NCC", substr($data, $offset, 6));
		last unless (($offset += 6) < $length); # $offset += 6;

		# printf("CollectAdobeParts: ID %2.2x %2.2x\n", $id1, $id2);
		
		# Get pascal string
		my ($stringlen) = unpack("C", substr($data, $offset, 1));
		last unless (++$offset < $length); # $offset += 1;

		# printf("CollectAdobeParts: str len %d\n", $stringlen);
		
		my $string = substr($data, $offset, $stringlen);
		$offset += $stringlen;
		# round up if odd
		$offset++ if ($stringlen % 2 != 0);
		# there should be a null if string len is 0
		$offset++ if ($stringlen == 0);
		last unless ($offset < $length);

		# Get variable-size data
		my ($size) = unpack("N", substr($data, $offset, 4));
		last unless (($offset += 4) < $length);  # $offset += 4;

		# printf("CollectAdobeParts: size %d\n", $size);

		my $var = substr($data, $offset, $size);
		$offset += $size;
		$offset++ if ($size % 2 != 0); # round up if odd

		# skip IIM data (0x0404), but write everything else out
		unless ($id1 == 4 && $id2 == 4)
		{
			$out .= pack("NCC", $ostype, $id1, $id2);
			$out .= pack("C", $stringlen);
			$out .= $string;
			$out .= pack("C", 0) if ($stringlen == 0 || $stringlen % 2 != 0);
			$out .= pack("N", $size);
			$out .= $var;
			$out .= pack("C", 0) if ($size % 2 != 0 && length($out) % 2 != 0);
		}
	}

	return $out;
}

#
# PackedIIMData
#
# Assembles and returns our _data and _listdata into IIM format for
# embedding into an image.
#
sub PackedIIMData
{
	my $self = shift;
	my $out;

	# First, we need to build a mapping of datanames to dataset
	# numbers if we haven't already.
	unless (scalar(keys %datanames))
	{
		foreach my $dataset (keys %datasets)
		{
			my $dataname = $datasets{$dataset};
			$datanames{$dataname} = $dataset;
		}
	}

	# Ditto for the lists
	unless (scalar(keys %listdatanames))
	{
		foreach my $dataset (keys %listdatasets)
		{
			my $dataname = $listdatasets{$dataset};
			$listdatanames{$dataname} = $dataset;
		}
	}

	# Print record version
	# tag - record - dataset - len (short) - 2 (short)
	$out .= pack("CCCnn", 0x1c, 2, 0, 2, 2);

	# Iterate over data sets
	foreach my $key (keys %{$self->{_data}})
	{
		my $dataset = $datanames{$key};
		my $value   = $self->{_data}->{$key};

		if ($dataset == 0)
		{ Log("PackedIIMData: illegal dataname $key"); next; }

        next unless $value;

		my ($tag, $record) = (0x1c, 0x02);

		$out .= pack("CCCn", $tag, $record, $dataset, length($value));
		$out .= $value;
	}

	# Do the same for list data sets
	foreach my $key (keys %{$self->{_listdata}})
	{
		my $dataset = $listdatanames{$key};

		if ($dataset == 0)
		{ Log("PackedIIMData: illegal dataname $key"); next; }

		foreach my $value (@{$self->{_listdata}->{$key}})
		{
		    next unless $value;
		    
			my ($tag, $record) = (0x1c, 0x02);

			$out .= pack("CCCn", $tag, $record, $dataset, length($value));
			$out .= $value;
		}
	}

	return $out;
}

#
# PhotoshopIIMBlock
#
# Assembles the blob of Photoshop "resource data" that includes our
# fresh IIM data (from PackedIIMData) and the other Adobe parts we
# found in the file, if there were any.
#
sub PhotoshopIIMBlock
{
	my ($self, $otherparts, $data) = @_;
	my $resourceBlock;
	my $out;

	$resourceBlock .= "Photoshop 3.0";
	$resourceBlock .= pack("C", 0);
	# Photoshop identifier
	$resourceBlock .= "8BIM";
	# 0x0404 is IIM data, 00 is required empty string
	$resourceBlock .= pack("CCCC", 0x04, 0x04, 0, 0);
	# length of data as 32-bit, network-byte order
	$resourceBlock .= pack("N", length($data));
	# Now tack data on there
	$resourceBlock .= $data;
	# Pad with a blank if not even size
	$resourceBlock .= pack("C", 0) if (length($data) % 2 != 0);
	# Finally tack on other data
	$resourceBlock .= $otherparts if defined($otherparts);

	$out .= pack("CC", 0xff, 0xed); # JPEG start of block, APP13
	$out .= pack("n", length($resourceBlock) + 2); # length
	$out .= $resourceBlock;

	return $out;
}

#######################################################################
# Helpers, docs
#######################################################################

#
# Log: just prints a message to STDERR if $debugMode is on.
#
sub Log
{
	if ($debugMode)
	{ my $message = shift; print STDERR "**IPTC** $message\n"; }
} 

#
# HexDump
#
# Very helpful when debugging.
#
sub HexDump
{
	my $dump = shift;
	my $len  = length($dump);
	my $offset = 0;
	my ($dcol1, $dcol2);

	while ($offset < $len)
	{
		my $temp = substr($dump, $offset++, 1);

		my $hex = unpack("H*", $temp);
		$dcol1 .= " " . $hex;
		if (ord($temp) >= 0x21 && ord($temp) <= 0x7e)
		{ $dcol2 .= " $temp"; }
		else
		{ $dcol2 .= " ."; }

		if ($offset % 16 == 0)
		{
			print STDERR $dcol1 . " | " . $dcol2 . "\n";
			undef $dcol1; undef $dcol2;
		}
	}

	if (defined($dcol1) || defined($dcol2))
	{
		print STDERR $dcol1 . " | " . $dcol2 . "\n";
		undef $dcol1; undef $dcol2;
	}
}

#
# JPEGDebugScan
#
# Also very helpful when debugging.
#
sub JPEGDebugScan
{
	my $filename = shift;
	my $handle = IO::File->new($filename);
	$handle or die "Can't open $filename: $!";

	# Skip past start of file marker
	my ($ff, $soi);
	$handle->read($ff, 1) || return 0;
	$handle->read($soi, 1);
	
	unless (ord($ff) == 0xff && ord($soi) == 0xd8)
	{
		Log("JPEGScan: invalid start of file");
		goto done;
	}

	# scan to 0xDA (start of scan), dumping the markers we see between
	# here and there.
	my $marker = JPEGNextMarker($handle);

	while (ord($marker) != 0xda)
	{
		if (ord($marker) == 0)
		{ Log("Marker scan failed"); goto done; }

		if (ord($marker) == 0xd9)
		{Log("Marker scan hit end of image marker"); goto done; }

		if (JPEGSkipVariable($handle) == 0)
		{ Log("JPEGSkipVariable failed"); return 0; }

		$marker = JPEGNextMarker($handle);
	}

done:
	$handle->close();
}

# sucessful package load
1;

__END__

=head1 NAME

Image::IPTCInfo - Perl extension for extracting IPTC image meta-data

=head1 SYNOPSIS

  use Image::IPTCInfo;

  # Create new info object
  my $info = new Image::IPTCInfo('file-name-here.jpg');

  # Check if file had IPTC data
  unless (defined($info)) { die Image::IPTCInfo::Error(); }
    
  # Get list of keywords, supplemental categories, or contacts
  my $keywordsRef = $info->Keywords();
  my $suppCatsRef = $info->SupplementalCategories();
  my $contactsRef = $info->Contacts();
    
  # Get specific attributes...
  my $caption = $info->Attribute('caption/abstract');
    
  # Create object for file that may or may not have IPTC data.
  $info = create Image::IPTCInfo('file-name-here.jpg');
    
  # Add/change an attribute
  $info->SetAttribute('caption/abstract', 'Witty caption here');

  # Save new info to file 
  ##### See disclaimer in 'SAVING FILES' section #####
  $info->Save();
  $info->SaveAs('new-file-name.jpg');

=head1 DESCRIPTION

Ever wish you add information to your photos like a caption, the place
you took it, the date, and perhaps even keywords and categories? You
already can. The International Press Telecommunications Council (IPTC)
defines a format for exchanging meta-information in news content, and
that includes photographs. You can embed all kinds of information in
your images. The trick is putting it to use.

That's where this IPTCInfo Perl module comes into play. You can embed
information using many programs, including Adobe Photoshop, and
IPTCInfo will let your web server -- and other automated server
programs -- pull it back out. You can use the information directly in
Perl programs, export it to XML, or even export SQL statements ready
to be fed into a database.

=head1 USING IPTCINFO

Install the module as documented in the README file. You can try out
the demo program called "demo.pl" which extracts info from the images
in the "demo-images" directory.

To integrate with your own code, simply do something like what's in
the synopsys above.

The complete list of possible attributes is given below. These are as
specified in the IPTC IIM standard, version 4. Keywords and categories
are handled differently: since these are lists, the module allows you
to access them as Perl lists. Call Keywords() and Categories() to get
a reference to each list.

=head2 NEW VS. CREATE

You can either create an object using new() or create():

  $info = new Image::IPTCInfo('file-name-here.jpg');
  $info = create Image::IPTCInfo('file-name-here.jpg');

new() will create a new object only if the file had IPTC data in it.
It will return undef otherwise, and you can check Error() to see what
the reason was. Using create(), on the other hand, always returns a
new IPTCInfo object if there was data or not. If there wasn't any IPTC
info there, calling Attribute() on anything will just return undef;
i.e. the info object will be more-or-less empty.

If you're only reading IPTC data, call new(). If you want to add or
change info, call create(). Even if there's no useful stuff in the
info object, you can then start adding attributes and save the file.
That brings us to the next topic....

=head2 MODIFYING IPTC DATA

You can modify IPTC data in JPEG files and save the file back to
disk. Here are the commands for doing so:

  # Set a given attribute
  $info->SetAttribute('iptc attribute here', 'new value here');

  # Clear the keywords or supp. categories list
  $info->ClearKeywords();
  $info->ClearSupplementalCategories();
  $info->ClearContacts();

  # Add keywords or supp. categories
  $info->AddKeyword('frob');

  # You can also add a list reference
  $info->AddKeyword(['frob', 'nob', 'widget']);

=head2 SAVING FILES

With JPEG files you can add/change attributes, add keywords, etc., and
then call:

  $info->Save();
  $info->SaveAs('new-file-name.jpg');

This will save the file with the updated IPTC info. Please only run
this on *copies* of your images -- not your precious originals! --
because I'm not liable for any corruption of your images. (If you read
software license agreements, nobody else is liable, either. Make
backups of your originals!)

If you're into image wizardry, there are a couple handy options you
can use on saving. One feature is to trash the Adobe block of data,
which contains IPTC info, color settings, Photoshop print settings,
and stuff like that. The other is to trash all application blocks,
including stuff like EXIF and FlashPix data. This can be handy for
reducing file sizes. The options are passed as a hashref to Save() and
SaveAs(), e.g.:

  $info->Save({'discardAdobeParts' => 'on'});
  $info->SaveAs('new-file-name.jpg', {'discardAppParts' => 'on'});

Note that if there was IPTC info in the image, or you added some
yourself, the new image will have an Adobe part with only the IPTC
information.

=head2 XML AND SQL EXPORT FEATURES

IPTCInfo also allows you to easily generate XML and SQL from the image
metadata. For XML, call:

  $xml = $info->ExportXML('entity-name', \%extra-data,
                          'optional output file name');

This returns XML containing all image metadata. Attribute names are
translated into XML tags, making adjustments to spaces and slashes for
compatibility. (Spaces become underbars, slashes become dashes.) You
provide an entity name; all data will be contained within this entity.
You can optionally provides a reference to a hash of extra data. This
will get put into the XML, too. (Example: you may want to put info on
the image's location into the XML.) Keys must be valid XML tag names.
You can also provide a filename, and the XML will be dumped into
there. See the "demo.pl" script for examples.

For SQL, it goes like this: 

  my %mappings = (
       'IPTC dataset name here' => 'your table column name here',
       'caption/abstract'       => 'caption',
       'city'                   => 'city',
       'province/state'         => 'state); # etc etc etc.
    
  $statement = $info->ExportSQL('mytable', \%mappings, \%extra-data);

This returns a SQL statement to insert into your given table name a
set of values from the image. You pass in a reference to a hash which
maps IPTC dataset names into column names for the database table. As
with XML export, you can also provide extra information to be stuck
into the SQL.

=head1 IPTC ATTRIBUTE REFERENCE

  object name               originating program
  edit status               program version
  editorial update          object cycle
  urgency                   by-line
  subject reference         by-line title
  category                  city
  fixture identifier        sub-location
  content location code     province/state
  content location name     country/primary location code
  release date              country/primary location name
  release time              original transmission reference
  expiration date           headline
  expiration time           credit
  special instructions      source
  action advised            copyright notice
  reference service         contact
  reference date            caption/abstract
  reference number          local caption
  date created              writer/editor
  time created              image type
  digital creation date     image orientation
  digital creation time     language identifier

  custom1 - custom20: NOT STANDARD but used by Fotostation.
  IPTCInfo also supports these fields.

=head1 KNOWN BUGS

IPTC meta-info on MacOS may be stored in the resource fork instead
of the data fork. This program will currently not scan the resource
fork.

I have heard that some programs will embed IPTC info at the end of the
file instead of the beginning. The module will currently only look
near the front of the file. If you have a file with IPTC data that
IPTCInfo can't find, please contact me! I would like to ensure
IPTCInfo works with everyone's files.

=head1 AUTHOR

Josh Carter, josh@multipart-mixed.com

=head1 SEE ALSO

perl(1).

=cut
