#!/bin/perl
#
# Usage: cvs log -rKDE_3_3_1_RELEASE -rKDE_3_3_2_RELEASE | cvslog2changelog.pl > file
#

sub findNextFile()
{
  while(<>)
  {
    return $_ if ($_ =~ /^RCS file:/);
  }
  return 0;
}

sub findLogStart()
{
  # Check last line
  return 1 if ($_ =~ /^--------------/);
  return 0 if ($_ =~ /^==============/);
  while(<>)
  {
    return 1 if ($_ =~ /^--------------/);
    return 0 if ($_ =~ /^==============/);
  }
  return 0;
}

sub findLogEntry()
{
  return 0 if (!findLogStart());
  my $log = $_;
  while(<>)
  {
    return $log if ($_ =~ /^==============/);
    return $log if ($_ =~ /^--------------/);
    if ($_ =~ /^revision /)
       { $revision = $_ }
    elsif (!($_ =~ /^date:/))
       { $log .= $_ }
  }
  return $log;
}

my $file;
my $last_file = '';
my %log_entries;
while($file = findNextFile())
{
   ($file) = ( $file =~ /\/home\/kde\/([^,]*)/);
   ($file) = ( $file =~ /(.*)\/[^\/]*/);
   next if ( $file =~ /^kde-common/);
   my $log_entry;
   my $last_log_entry;
   my $skip_first = 0;

   # Don't print the last log entry
   $last_log_entry = findLogEntry();
   $last_revision = $revision;
   while($log_entry = findLogEntry())
   {
      if (length $revision > length $last_revision)
      {
         # CVS tends to put r1.45 in front of r1.45.2.1
         # In that case we need to skip the first entry instead of the last
         $skip_first = 1;
      }
      $last_log_entry = $log_entry if ($skip_first);

      if (! ($last_log_entry =~ /CVS_SILENT/))
      {
         if ($last_file ne $file)
         {
            # dump log_entries
            foreach my $key (keys %log_entries)
            {
               print $key;
            }
            %log_entries = ();
            print "\n\n\n" if ($last_file);
            print "Dir: $file\n";
            $last_file = $file;
         }
         $log_entries{$last_log_entry} = 1;
      }

      $last_log_entry = $log_entry;
      $last_revision = $revision;
   }
}

# dump remaining log_entries
foreach my $key (keys %log_entries)
{
   print $key;
}
