#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Temp qw(tempfile);
use File::Basename;
use Data::Dumper;

my $cc = "gcc";
my $cflags = "";
my $out_dir = ".";
my $no_filter = 0;

my $result = GetOptions(
	"cc=s"       => \$cc,
	"cflags=s"   => \$cflags,
	"out_dir=s"  => \$out_dir,
	"no_filter"  => \$no_filter,
);

if (!$result) {
	die "Failed to parse command line\n";
}

my @keywords = qw(
	type
	elseif
	end
	function
	in
	local
	nil
	not
	repeat
	then
	until
);

my @ignores = qw(
	__typeof__
	__BEGIN_DECLS
	__END_DECLS
);

sub replace_keywords {
	my ($output, $line) = @_;
	foreach my $ignore (@ignores) {
		if ($line =~ /\b$ignore\b/) {
			$$output .= "/* Ignoring line with $ignore */\n";
			return "/* $line */";
		}
	}
	if ($line =~ /^\s*static .*?;\s*$/) {
		$$output .= "/* Ignoring static declaration */\n";
		chomp($line);
		return "/* $line */\n";
	}
	foreach my $keyword (@keywords) {
		if ($line =~ /\b$keyword\b/) {
			$$output .= "/* Replacing $keyword with ${keyword}_ */\n";
			$line =~ s/\b$keyword\b/${keyword}_/g;
		}
	}
	return $line;
}

my %contents;
my %deps;

sub preprocess {
	my ($what) = @_;
	my (undef, $filename) = tempfile("/tmp/ffi.h.XXXXXX", OPEN => 0);
	#print("\n\n$cc $cflags -E $what -o $filename\n");
	system("$cc $cflags -E $what -o $filename");
	if ($? == -1) {
		die "failed to execute: $!\n";
	} elsif ($? & 127) {
		die sprintf("child died with signal %d, %s coredump\n",
			($? & 127),  ($? & 128) ? 'with' : 'without');
	} else {
		my $value = $? >> 8;
		if (0 != $value) {
			die sprintf("child exited with value %d\n", $? >> 8);
		}
	}
	return $filename;
}

sub generate_file_output {
	my ($file) = @_;
	my $output = "";
	foreach my $dep (@{$deps{$file}}) {
		$output .= generate_file_output($dep);
	}
	return $output if !$contents{$file};
       	$output .= "\n";
	$output .= "if not FFI_INCLUDED[\"$file\"] then\n";
	$output .= "\tFFI_INCLUDED[\"$file\"] = true\n";
	$output .= "\tffi.cdef[[\n";
	$output .= $contents{$file};
	$output .= "\t]]\n";
	$output .= "end\n";
}

sub process_file {
	my ($file) = (@_);
	my $do_output = 0;
	my $header = "";
	my $filtered_output = "";
	my $footer = "";
	my $is_terminal = 0;

	my $pp_file = preprocess($file);
	$header .= "local ffi = require(\"ffi\")\n";
	$header .= "if nil == FFI_INCLUDED then\n";
	$header .= "\tFFI_INCLUDED = {}\n";
	$header .= "end\n";

	my %includes;
	my @includes;

	if ($no_filter) {
		$do_output = 1;
	}

	my $src_basename = basename($file, '.h');
	my $dest_filename = "$out_dir/$src_basename\_h.lua";
	open(OUT_FILE, ">", $dest_filename) or
		die "Failed to open $dest_filename\n";
	open(SRC_FILE, "<", $pp_file) or die "Failed to open $pp_file\n";
	my %visited;
	my $current;
	my $top;
	while (my $line = <SRC_FILE>) {
		next if $line =~ /^\s*$/;
		if ($line =~ /^# \d+ "([^"]+)"/) {
			my $file = $1;
			if (!defined($current)) {
				$current = $file;
				$visited{$file} = 1;
				$top = $file;
			} else {
				if (!$visited{$file}) {
					$deps{$current} = [] if !$deps{$current};
					push(@{$deps{$current}}, $file);
					$visited{$file} = 1;
				}
				$current = $file;
			}
		} else {
			$line = replace_keywords(\$filtered_output, $line);
			$contents{$current} = "" if !$contents{$current};
			$contents{$current} .= $line;
		}
	}
	close SRC_FILE;
	unlink($pp_file);

	$footer .= "";

	print OUT_FILE $header;
	print OUT_FILE generate_file_output($top);
	print OUT_FILE $footer;
	close(OUT_FILE);
}


foreach my $arg (@ARGV) {
	process_file($arg);
}
