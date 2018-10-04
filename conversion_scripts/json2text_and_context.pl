#!/usr/bin/perl -X


use strict;
use utf8;
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';
use Getopt::Long;
use File::Spec::Functions qw(rel2abs);
use JSON::PP;


my $helpstring = "Usage: $0 [options]
available options are:
--help|h: print this help
--source|s: source language
--target|t: target language
--dir|d: directoy with sentence aligned text files
--json|j: json test set
--context|c: print n context sentences (both source and target, default: 1)
--no-contrastives: do not print contrastive sentence pairs, print only source and reference
--verbose|v: be verbose\n";


my $help;
my $source;
my $target;
my $dir;
my $json_file;
my $context=1;
my $no_contrastives=0;
my $verbose = '';

GetOptions(
	# general options
    'help|h'     => \$help,
    'source|s=s' => \$source,
    'target|t=s' => \$target,
    'dir|d=s' => \$dir,
    'json|j=s' => \$json_file,
    'context|c=i' => \$context,
    'no-contrastives|s' => \$no_contrastives,
    'verbose|v' => \$verbose
) or die "Incorrect usage!\n $helpstring";

if($help or !($source and $target and $dir and $json_file)){ print STDERR $helpstring; exit;}


opendir(DIR, $dir) or die "can't open directory $dir: $!";

## opensubs
my %sent_aligned_files=();
while (defined(my $subfolder = readdir(DIR))) {
    opendir(SUBDIR, "$dir/$subfolder") or die "can't open directory $subfolder: $!";
    while (defined(my $file = readdir(SUBDIR))) {
    if($file =~ /\.$source$/){
      my $abs_path_file_s = File::Spec->rel2abs( "$dir/$subfolder/".$file ) ;
      ## target file:
      $file =~ s/$source$/$target/ ;
      my $abs_path_file_t = File::Spec->rel2abs( "$dir/$subfolder/".$file ) ;
      $sent_aligned_files{$abs_path_file_s}=$abs_path_file_t;
    }
    }
    close(SUBDIR)
}
closedir(DIR);

my %filenames = ();

foreach my $s_file (keys %sent_aligned_files){

  my $t_file = $sent_aligned_files{$s_file};
  
  ## read sentence alignments
  open (SOURCE, "<:encoding(UTF-8)", $s_file) or die "Can't open source file $s_file: $!\n"; 
  open (TARGET, "<:encoding(UTF-8)", $t_file) or die "Can't open target file $t_file: $!\n"; 
  
  ## read segments into arrays
  my @source_segs =  <SOURCE>;
  my @target_segs =  <TARGET>;
  unshift @source_segs, "null"; ## unshift because line numbers in json start with 1, not 0
  unshift @target_segs, "null";
  
  die "source file $s_file and target file $t_file are of different length! cannot convert json to text." if (scalar(@source_segs) != scalar(@target_segs));
  
   my ($filename) = ($t_file =~ m/([^\/]+)$/); ## document id in json is de file
  $filenames{$filename}{"src"} = \@source_segs;
  $filenames{$filename}{"trg"} = \@target_segs;  
}


my $data;
my $json;
my @shortjson;
my ($outname) = ($json_file =~ m/([^\/]+).json/);

local $/; #Enable 'slurp' mode
open my $fh, "<", $json_file;
$data = <$fh>;
close $fh;
$json = decode_json($data);

my $out_source_text= "$outname.text.$source" ;
my $out_source_context= "$outname.context.$source" ;
my $out_target_text= "$outname.text.$target" ;
my $out_target_context= "$outname.context.$target" ;
open (OUT_S_TEXT, ">:encoding(UTF-8)", $out_source_text) or die "Can't open source file $out_source_text: $!\n"; 
open (OUT_T_TEXT, ">:encoding(UTF-8)", $out_target_text) or die "Can't open source file $out_target_text: $!\n"; 
open (OUT_S_CONTEXT, ">:encoding(UTF-8)", $out_source_context) or die "Can't open source file $out_source_context: $!\n"; 
open (OUT_T_CONTEXT, ">:encoding(UTF-8)", $out_target_context) or die "Can't open source file $out_target_context: $!\n";



my $sentpair_count=0;
print STDERR "src-trg sentence pairs = ".scalar(@$json)."\n";



foreach my $sentence_pair (@$json){
    my $filename = $sentence_pair->{'document id'};
 
    ## check for missing files
    if(!(exists($filenames{$filename}))){
        print STDERR "missing file: $filename\n";
        exit(0);
    }
    
    my $ref_prn = lc($sentence_pair->{'ref pronoun'});
    my $line = $sentence_pair->{'segment id'};
    my $source = @{$filenames{$filename}{"src"}}[$line];
    #       
    if($source and &noWS($source) eq &noWS($sentence_pair->{'source'}) ){ ## check if we have the same sentence in document and json
               
                if($line>1){
                    for(my $c=$context;$c>=1;$c--){
                        print OUT_S_CONTEXT @{$filenames{$filename}{"src"}}[$line-$c];
                        print OUT_T_CONTEXT @{$filenames{$filename}{"trg"}}[$line-$c];
                    }
                }
                elsif($line=1){
                    print OUT_S_CONTEXT "\n";
                    print OUT_T_CONTEXT "\n";
                }
                ## print this source and contrastive sentence from error
                print OUT_S_TEXT "$source";
                print OUT_T_TEXT @{$filenames{$filename}{"trg"}}[$line];
                
                
                unless($no_contrastives){
                    foreach my $error (@{$sentence_pair->{'errors'}}){
                        my $contrastive = $error->{'contrastive'};
                        
                        if($line>1){
                            ## print context up to and including sentence -1 from current sentence
                            for(my $c=$context;$c>=1;$c--){
                                print OUT_S_CONTEXT @{$filenames{$filename}{"src"}}[$line-$c];
                                print OUT_T_CONTEXT @{$filenames{$filename}{"trg"}}[$line-$c];
                            }
                        }
                        elsif($line=1){
                            print OUT_S_CONTEXT "\n";
                            print OUT_T_CONTEXT "\n";
                        }
                        ## print this source and contrastive sentence from error
                        print OUT_S_TEXT "$source";
                        print OUT_T_TEXT "$contrastive\n";
                        
                    }
                }
                
     }
	else{
        die "source sentence $line in $filename not found or doc source and json source \n $source\n ".$sentence_pair->{'source'}."\n not the same";
    }
}



sub noWS{
 my $string = $_[0];
 return $string =~ s/\s\t\n//g;
}












