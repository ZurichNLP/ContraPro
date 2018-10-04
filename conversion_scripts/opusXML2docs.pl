#!/usr/bin/perl -X


use strict;
use utf8;
#binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';
use Getopt::Long;
# use XML::LibXML;


my $helpstring = "Usage: $0 [options]
available options are:
--help|h: print this help
--ids|i: ids file
--source|s: source corpus
--target|t: target corpus
--l1: source language
--l2: target language
--filelist|f: optional list of filenames to print (print only files in the list)
--outdir
--verbose|v: be verbose\n";

my $help;
my $ids;
my $source;
my $target;
my $l1;
my $l2;
my $filelist;
my $outdir;
my $verbose = '';

GetOptions(
	# general options
    'help|h'     => \$help,
    'ids|i=s' => \$ids,
    'source|s=s' => \$source,
    'target|t=s' => \$target,
    'l1=s' => \$l1,
    'l2=s' => \$l2,
    'filelist=s' => \$filelist,
    'outdir=s' => \$outdir,
    'verbose|v' => \$verbose
) or die "Incorrect usage!\n $helpstring";

if($help or !$ids or !$target or !$source){ print STDERR $helpstring; exit;}

open (SOURCE, "<:encoding(UTF-8)", $source) or die "Can't open source file $source: $!\n"; 
open (TARGET, "<:encoding(UTF-8)", $target) or die "Can't open target file $target: $!\n"; 
open (IDS, "<:encoding(UTF-8)", $ids) or die "Can't open ids file $ids: $!\n";  
open (DOCORDER, ">:encoding(UTF-8)", "doc.order.$l1-$l2.txt") or die "Can't open ids file doc.order.$l1-$l2.txt: $!\n"; 

## read segments into arrays
my @source_segs =  <SOURCE>;
my @target_segs =  <TARGET>;
my @ids_segs =  <IDS>;
die "source file $source and target file $target are of different length! cannot extract segments." if (scalar(@source_segs) != scalar(@target_segs));


my %docs =();
my @docorder;
my $prevfilename ="";

for (my $i=0;$i<scalar(@source_segs);$i++){
    my $ids_line = @ids_segs[$i];
#      my $source_line = @source_segs[$i];
#     my $target_line = @target_segs[$i];
    my ($filename) =  ($ids_line =~ /..\/([^\/\s\t]+)[\/\t\s\n]/);
    if($filename =~ /^ep/) ## europarl do not split paragraphs
    {
# 	$filename =~ s/\.xml\.gz$//;
	my $doc = "";
	($doc) = ($filename =~ /^(ep-\d\d-\d\d-\d\d-\d\d\d)/);
	if($doc eq ""){
	   ($doc) = ($filename =~ /^(ep-\d\d-\d\d-\d\d)/);
	}
	$filename = $doc;
    }
    if($ids =~ /OpenSubtitles/){
      ($filename) =  ($ids_line =~ /(\d\d\d\d\/\d+\/\d+)\.xml/);
       ## replace '/' in Opensubtitle filenames with _
       $filename =~ s/\//\_/g;
    }
    $filename =~ s/\_?\.xml\.gz//;
   
    print STDERR "filename $filename\n" if $verbose;
    $docs{$filename}{$i} = 1;
    if($prevfilename ne $filename){
      push(@docorder,$filename);
      print DOCORDER $filename."\n";
      $prevfilename=$filename;
    }
     
}

# my $outpath = "documents_".$l1."_".$l2;
# my $outpath = "EUbookshop_documents/";

my $outpath = $outdir;

if($filelist){
  open (FILES, "<:encoding(UTF-8)", $filelist) or die "Can't open list of filenames $filelist: $!\n" ;
  my @files_to_print =  <FILES> ;
#   print STDERR "files to print $filelist".scalar(@files_to_print)."\n";
  
  foreach my $filename (@files_to_print){
    $filename =~ s/\n//;
    
    ## replace '/' in Opensubtitle names with _
    $filename =~ s/\//\_/g;
    
    my $outname1=$outpath."/".$filename.".$l1";
    my $outname2=$outpath."/".$filename.".$l2"; 
    
    print STDERR "filename: $filename $outname1\n";
  
    open (OUTFILE_S, ">:encoding(UTF-8)", $outname1) or die "Can't open output file $outname1: $!\n";
  #   open (OUTFILE_T, ">:encoding(UTF-8)", $outpath."$filename.en") or die "Can't open ids file $outpath.$filename.en: $!\n";
    open (OUTFILE_T, ">:encoding(UTF-8)", $outname2) or die "Can't open output file $outname2: $!\n";
  
    foreach my $line (sort  { $a <=> $b } keys %{$docs{$filename}}){
	my $source_line = @source_segs[$line];
	my $target_line = @target_segs[$line];
	print OUTFILE_S $source_line;
	print OUTFILE_T $target_line;
    }
    close(OUTFILE_S);
    close(OUTFILE_T);

  }  
}
else{
  foreach my $filename (@docorder){

    my $outname1=$outpath."/".$filename.".$l1";
    my $outname2=$outpath."/".$filename.".$l2"; 
    
#     print STDERR "filename: $filename $outname1\n"  if $verbose;
  
    open (OUTFILE_S, ">:encoding(UTF-8)", $outname1) or die "Can't open output file $outname1: $!\n";
  #   open (OUTFILE_T, ">:encoding(UTF-8)", $outpath."$filename.en") or die "Can't open ids file $outpath.$filename.en: $!\n";
    open (OUTFILE_T, ">:encoding(UTF-8)", $outname2) or die "Can't open output file $outname2: $!\n";
  
    foreach my $line (sort  { $a <=> $b } keys %{$docs{$filename}}){
	my $source_line = @source_segs[$line];
	my $target_line = @target_segs[$line];
	print OUTFILE_S $source_line;
	print OUTFILE_T $target_line;
    }
    close(OUTFILE_S);
    close(OUTFILE_T);

  }  
}  
close(SOURCE);
close(TARGET);
close(IDS);
close(DOCORDER);
