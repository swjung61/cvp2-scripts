#!/usr/bin/perl -w

use strict;
use File::Glob qw(:glob :globally :nocase);
use File::Find;
use File::Spec;
use File::Path;
use File::stat qw(:FIELDS);

my @new_copyright_header=(
" * Copyright (C) 2013  Cable Television Laboratories, Inc.
 * Contact: http://www.cablelabs.com/
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS
 * IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CABLE TELEVISION LABORATORIES
 * INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
");

die "Usage: $0 [-dryrun] targetdir(s)\n\nReplace Rygel copyright headers recursively in <targetdirs>\n" if $#ARGV < 0;

my $dryrun = 0;
if (($ARGV[0] =~ "-dry-run") || ($ARGV[0] =~ "--dry-run"))
{
    $dryrun = 1;
    shift;
}

if ($dryrun)
{
   print "Performing DRY RUN copyright replacement in directories:\n";
}
else
{
   print "Performing copyright replacement in directories:\n";
}

for my $dir (@ARGV)
{
    print "  \"$dir\"\n";
}

print "Press RETURN to start\n";

my $linein = <STDIN>;

find sub 
{
    if ( -d )
    {
        my $dirpath = $File::Find::name;
        # print "DIRECTORY: $dirpath\n";
    }
    else
    { # Looking at a file
        my $filepath = $File::Find::name;

        my ($filevol,$filedir,$filename) = File::Spec->splitpath( $filepath );

        # Change this to match patterns you want to skip (e.g. .svn/.git in the path)
        if ($filedir =~ /(\.git|\.svn|\.deps|\.libs)/)
        {
            print "SKIPPING (filename excluded): $filepath\n";
        }
        # Change this to match patterns you want to check
        elsif ( ($filepath =~ /\.vala$/) 
                 || ($filepath =~ /\.c$/)
                 || ($filepath =~ /\.h$/)
#                  || ($filepath =~ /\.cpp$/) 
              )
        {
            if ($dryrun) {
                print "  CHECKING: $filepath\n";
            }

            # We're going to look for any section of text in the first comment in the
            #  file starting with "Copyright <blah> Cable Television Laboratories, Inc."
            #  and ending with the end of the comment block, another instance of 
            #  'Copyright', an 'Author:' line, or the end of a comment...

            open FILE, "<$filename" or die $!;
            my @filebuffer=();
            my $in_first_comment = 0;
            my $in_cr_header = 0;
            my $done_inserting = 0;
            my $did_it = 0;

            while (my $line = <FILE>)
            {
                if ($done_inserting)
                { # Just copy the line
                    if ($dryrun) {
                        print "    COPY1: $line";
                    } else {
                        push @filebuffer,$line;
                    }
                }
                elsif ( ! $in_first_comment)
                {
                    if ($line =~ /^\s*\/\*/)
                    {
                        $in_first_comment = 1;
                    }
                    if ($dryrun) {
                        print "    COPY2: $line";
                    } else {
                        push @filebuffer,$line;
                    }
                }
                elsif ($in_first_comment && ! $in_cr_header)
                {
                    if ($line =~ /^\s*\*\s*Copyright\s+\([cC]\)\s+(\d\d\d\d)\s+Cable Television Laboratories, Inc\./)
                    {
                        $in_cr_header = 1; 
                        if ($dryrun) {
                            print "    REMOVE1: $line";
                        } 
                    }
                    elsif (! ($line =~ /^\s\*\s$/))
                    { # Allow for lines of leading " * ". Otherwise we're done looking
                        $in_first_comment = 0;
                        $done_inserting = 1;
                        if ($dryrun) {
                            print "    COPY3: $line";
                        } else {
                            push @filebuffer,$line;
                        }
                    }
                    else
                    {
                        # otherwise we're skipping lines
                        if ($dryrun) {
                            print "    REMOVE2: $line";
                        } 
                    }
                }
                elsif ($in_cr_header)
                {
                    if ( ($line =~ /Author: /) 
                         || ($line =~ /^\s*\*\//) 
                         || ($line =~ /^\s*\*\s*Copyright/) )
                    {
                        if ($dryrun) {
                            print "    INSERT:\n";
                            print "@new_copyright_header";
                            print "    COPY4: $line\n";
                        } else {
                            push @filebuffer,@new_copyright_header;
                            push @filebuffer,$line;
                            $did_it = 1;
                        }
                        $done_inserting = 1;
                    }
                    else
                    {
                        # otherwise we're skipping lines
                        if ($dryrun) {
                            print "    REMOVE3: $line";
                        } 
                    }
                }
                else
                { # Just copy the line
                    if ($dryrun) {
                        print "    COP5: $line";
                    } else {
                        push @filebuffer,$line;
                    }
                }
            } # END while
            close FILE;
            # $filebuffer should be ready to go
            if ($did_it)
            {
                print "UPDATED COPYRIGHT: $filepath\n";
                if (!$dryrun)
                {
                    open FILE, ">$filename" or die $!;
                    print FILE @filebuffer;
                    close FILE;
                }
            }
            else
            {
                print "SKIPPING (no copyright found): $filepath\n";
            }
        }
        else
        {
            if ($dryrun) {
                print "SKIPPING (filename didn't match): $filepath\n";
            }
        }
    }
}, @ARGV;

