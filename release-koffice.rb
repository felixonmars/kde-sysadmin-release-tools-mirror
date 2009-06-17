#!/usr/bin/ruby

class ReleaseBase
  def executeCommand( command )
    puts "Execute the following command : '#{command}' ? (y/n)"
    if( askOk)
      system("#{command}")
      puts "Done executing '#{command}'."
      return true
    else
      return false
    end
  end
  def writeInFile(filename, string)
    puts "Write '#{string}' in '#{filename}' ? (y/n)"
    return unless askOk
    file = File.new(filename, "w")
    file.write(string)
    file.close
  end
  def checkFileContains(filename, string)
    file = File.new(filename, "r")
    filecontent = file.readlines
    if( not filecontent.join().include?(string) )
      puts "File '#{filename}' doesn't contains '#{string}'. (press enter once fixed)"
      gets
      checkFileContains(filename, string)
    end
  end
  def checkFileContainsOnly(filename, string)
    file = File.new(filename, "r")
    filecontent = file.readlines
    if( not filecontent.join() == string )
      puts "File '#{filename}' isn't equal to '#{string}'. (press enter once fixed)"
      gets
      checkFileContains(filename, string)
    end
  end
  
  def checkDirectory( directory )
    if( not File.directory?(directory) )
      puts "Directory #{directory} not found."
      executeCommand( "mkdir #{directory}")
      checkDirectory( directory )
    end
  end
  def askOk
    a = gets.chomp
    if( a == 'y' or a == 'yes')
      return true
    elsif( a == 'n' or a == 'no')
      return false
    end
    puts "Please answer by 'yes' or 'no'."
    return askOk
  end
end

class ReleaseKoffice < ReleaseBase
  def initialize
    puts "Release KOffice script will help you to go step-by-step to release KOffice"
    askQuestions()
    puts "================= Checking for directories ================="
    checkDirectory("./clean")
    checkDirectory("./sources-old")
    checkDirectory("./sources")
    checkDirectory("./dirty")
    checkDirectory("./test")
    checkDirectory("./build")
    checkDirectory("./done")
    puts "================= Checking 'versions' file ================="
    checkFileContains('versions', "HEADURL=#{svnSourcePath()}")
    checkFileContains('versions', "DESTURL=#{svnDestinationPath()}")
    if(@release_l10n)
      checkFileContains('versions', "DESTURL=#{svnL10nDestinationPath()}")
      if(@release_source == "branch")
        checkFileContains('versions', "HEADURL=branches/stable/l10n-kde4")
      else
        checkFileContains('versions', "HEADURL=trunk/l10n-kde4")
      end
    end
    puts "================== Checking 'common' file =================="
    checkFileContains('common', "koffice)\n    version=#{@koffice_version}")
    if(@release_l10n)
      checkFileContains('common', "koffice-l10n)\n    version=#{@koffice_version}")
    end
    puts "==================== Update modules file ==================="
    writeInFile('modules', 'koffice')
    checkFileContainsOnly('modules', 'koffice')
    puts "========================= Checkout ========================="
    askSvnUser
    executeCommand("./checkout")
# TODO desktop-file-validate
# TODO check koffice version
# TODO    executeCommand("cd clean/koffice; find . -type f -name \"*.ui\" -exec fixuifiles {} ';'; cd ../..")
    puts "Please commits the changes, are you done ?"
    while(not askOk )
    end
    puts "=========================== test ==========================="
    executeCommand("cd build; mkdir koffice-test; cd koffice-test; cmake ../../clean/koffice; make -j3; cd ../..; ")
    executeCommand("rm -rf build/koffice-test;")
    gets
    
    puts "========================= tag_all =========================="
    executeCommand("./tag_all")
    # Often tag all don't correctly do the switch
    executeCommand("cd clean/koffice; svn switch https://svn.kde.org/home/kde/tags/koffice/#{@koffice_version}/koffice; cd ../..")
    puts "======================== removestuff ======================="
    executeCommand("cd clean; ../removestuff koffice; svn commit koffice; cd ..");
    if(@release_katelier)
      puts "========================= KAtelier ========================="
      executeCommand(<<KATELIER_TAG
          cd dirty;
          svn -N co #{ENV['SVNPROTOCOL']}://#{ENV['SVNUSER']}@svn.kde.org/home/kde/tags/koffice/#{@koffice_version}/ tagging;
          svn cp ../clean/koffice tagging/katelier;
          cd tagging/katelier;
          svn rm kexi kchart kformula kivio kplato kpresenter kspread kword kdgantt;
          cd filters;
          svn rm kchart kformula/ kivio/ kpresenter/ kspread/ kword/ liboofilter/ xsltfilter/ libdialogfilter/;
          cd ../..;
          svn commit;
          mv katelier ../../clean;
          cd ../
          rm -rf tagging
          cd ../;
KATELIER_TAG
      )

#       writeInFile('modules', "koffice\nkatelier")
      checkFileContains('modules', "katelier")
      checkFileContains('common', "katelier)\n    version=#{@koffice_version}")
    end
    if(@release_l10n)
      checkFileContains('modules', "koffice-l10n")
      case @release_source
        when "trunk"
          checkFileContains('koffice-l10n', "# KOFFICE_L10N=branches/stable/l10n-kde4")
          checkFileContains('koffice-l10n', "KOFFICE_L10N=trunk/l10n-kde4")
        when "branch"
          checkFileContains('koffice-l10n', "KOFFICE_L10N=branches/stable/l10n-kde4")
          checkFileContains('koffice-l10n', "# KOFFICE_L10N=trunk/l10n-kde4")
      end
      
      executeCommand("./koffice-l10n")
#       executeCommand("cd clean/tags-koffice/1.9.98.4/koffice-l10n/en_GB/messages/koffice; svn rm kexi.po kformula.po kivio.po ; cd ../../../../../../../")
      executeCommand("cd clean/tags-koffice/*/koffice-l10n && sh $OLDPWD/select-l10n")
      executeCommand("cd clean/tags-koffice/*/koffice-l10n && mv language_list.new subdirs")
      executeCommand("svn commit clean/tags-koffice")
      executeCommand("mv clean/tags-koffice/*/koffice-l10n clean")
      executeCommand("cd clean && DO_SVN=1 ../removestuff koffice-l10n")
      executeCommand("svn commit clean/koffice-l10n")
    end
    puts "=========================== pack ==========================="
    while( true )
      executeCommand("./pack_all")
      if( not File.exist?("sources/FAILED" ) )
        break
      else
        puts "Some failures has happen during packing"
        file = File.new(filename, "r")
        puts file.readlines
        puts "Try again ?"
        if( askOk )
          executeCommand( "rm sources/FAILED" )
        else
          break
        end
      end
    end
    # TODO do l10n
    puts "========================= signing =========================="
    if(@release_l10n)
      kde_i18n_files = "koffice-l10n/*.tar.bz2"
    else
      kde_i18n_files = ""
    end
    executeCommand("cd sources;md5sum *.tar.bz2 #{kde_i18n_files} > MD5SUMS; cd ..")
    executeCommand("cd sources;gpg --clearsign -a MD5SUMS; cd ..")
  end

  def askQuestions()
    askVersion()
    askBranchOrTrunk()
    askl10n()
    askKAtelier()
    puts "#########################################################################"
    puts "koffice_version = '#{@koffice_version}'"
    puts "koffice_version_major = '#{@koffice_version_major}'"
    puts "koffice_version_minor = '#{@koffice_version_minor}'"
    puts "koffice_version_release = '#{@koffice_version_release}'"
    puts ""
    puts "Release l10n = #{@release_l10n}"
    puts "Release KAtelier = #{@release_katelier}"
    puts ""
    puts "Release from = #{@release_source}"
    puts "Svn source = #{svnSourcePath()}"
    puts "Svn destination = #{svnDestinationPath()}"
    puts ""
    puts "Is it ok ? (y/n)"
    if( not askOk )
      askQuestions
    end
    # Sanity checks
    if( @koffice_version_release >= 50 and branchRelease?() )
      puts "Are you sure to release from branch with a verion number '#{@koffice_version}' used for beta/alpha/rcs ?"
      if(not askOk)
        askQuestions
      end
    end
    if( @koffice_version_release < 10 and trunkRelease?() )
      puts "Are you sure to release from trunk with a verion number '#{@koffice_version}' used for stable release ?"
      if(not askOk)
        askQuestions
      end
    end
    if( @koffice_version_release < 10 and not @release_l10n )
      puts "Are you sure to not release l10n with a verion number '#{@koffice_version}' used for stable release ?"
      if(not askOk)
        askQuestions
      end
    end
  end
  def askVersion()
    puts "Version number (e.g. 1.9.95.9):"
    @koffice_version = gets.chomp
    splited = @koffice_version.split('.')
    @koffice_version_major = splited[0].to_i
    @koffice_version_minor = splited[1].to_i
    @koffice_version_release = splited[2].to_i
  end
  def askBranchOrTrunk()
    puts "Choose the source of the release:"
    puts "(1) trunk"
    puts "(2) branch"
    a = gets.chomp
    if( a == "1" or a == "trunk" )
      @release_source = "trunk"
      return
    elsif( a == "2" or a == "branch" )
      @release_source = "branch"
      return
    end
    askBranchOrTrunk()
  end
  def askl10n()
    puts "Release l10n ? (y/n)"
    @release_l10n = askOk
  end
  def askKAtelier()
    puts "Release KAtelier ? (y/n)"
    @release_katelier = askOk
  end
  def branchRelease?()
    return @release_source == "branch"
  end
  def trunkRelease?()
    return @release_source == "trunk"
  end
  def svnSourcePath()
    case @release_source
      when "trunk"
        return "trunk/koffice"
      when "branch"
        return "branches/koffice/#{@koffice_version_major}.#{@koffice_version_minor}/koffice"
    end
  end
  def svnDestinationPath()
    return "tags/koffice/#{@koffice_version}/$1"
  end
  def svnL10nDestinationPath()
    return "tags/koffice/#{@koffice_version}/koffice-l10n"
  end
  def askSvnUser
    svnuser = ENV['SVNUSER']
    svnprotocol = ENV['SVNPROTOCOL']
    puts "$SVNUSER = '#{svnuser}' $SVNPROTOCOL='#{svnprotocol}', is it ok ? (y/n)"
    if(not askOk )
      puts "Svn user ?"
      ENV['SVNUSER'] = gets.chomp
      puts "Svn protocol ?"
      ENV['SVNPROTOCOL'] = gets.chomp
      askSvnUser
    end
  end
end

class TestL10n
  def initialize
    system("cd test")
    dirname = "sources/koffice-l10n"
    d = Dir.new(dirname)
    d.entries.each() { |x|
      unless( x== "." or x == "..")
        name = x.clone
        name[".tar.bz2"] = ""
        system("cd test;tar -xjf ../#{dirname}/#{x}")
        if(system("cd test/#{name};cmake . &>/dev/null; make &>/dev/null"))
          puts "#{name} has succeed"
        else
          puts "#{name} has failed"
        end
        system("rm -rf test/#{name}")
      end
    }
  end
end

class BranchL10n < ReleaseBase
  def initialize
    puts "Branch l10n this script will make you go step by step for copying translation into stable branch"
    subdirs = [ "data", "docmessages", "docs", "internal", "messages" ]
    subdirsSvnList = subdirs.join(" ")
    subdirsKOfficeSvnList = subdirs.join("/koffice ") + "/koffice"
    
    blacklist = [ "README", "subdirs", "teamnames" ]
    # Checkout branch
    executeCommand("svn -N co #{ENV['SVNPROTOCOL']}://#{ENV['SVNUSER']}@svn.kde.org/home/kde/branches/stable/l10n-kde4 l10n-kde4-stable")
    dirs = `svn ls #{ENV['SVNPROTOCOL']}://#{ENV['SVNUSER']}@svn.kde.org/home/kde/branches/stable/l10n-kde4`
    dirs.each() { |x|
      x = x[0, x.size-1]
      unless(blacklist.include?(x))
        system("cd l10n-kde4-stable; svn -N up #{x}")
        system("cd l10n-kde4-stable/#{x}; svn -N up #{subdirsSvnList}; svn up #{subdirsKOfficeSvnList};")
        subdirs.each() { |y|
          if( File.exists?("l10n-kde4-stable/#{x}/#{y}/koffice") )
            system("svn rm l10n-kde4-stable/#{x}/#{y}/koffice")
          end
        }
      end
    }
    executeCommand("svn commit l10n-kde4-stable")
    # Checkout trunk
    executeCommand("svn -N co #{ENV['SVNPROTOCOL']}://#{ENV['SVNUSER']}@svn.kde.org/home/kde/trunk/l10n-kde4 l10n-kde4-trunk")
    dirs = `svn ls #{ENV['SVNPROTOCOL']}://#{ENV['SVNUSER']}@svn.kde.org/home/kde/trunk/l10n-kde4`
    dirs.each() { |x|
      x = x[0, x.size-1]
      unless(blacklist.include?(x))
        system("cd l10n-kde4-trunk; svn -N up #{x}")
        system("cd l10n-kde4-trunk/#{x}; svn -N up #{subdirsSvnList}; svn up #{subdirsKOfficeSvnList};")
        subdirs.each() { |y|
          if( File.exists?("l10n-kde4-trunk/#{x}/#{y}/koffice") )
            unless(File.exists?("l10n-kde4-stable/#{x}/#{y}"))
              system("svn mkdir 10n-kde4-stable/#{x}/#{y}")
            end
            system("svn cp l10n-kde4-trunk/#{x}/#{y}/koffice l10n-kde4-stable/#{x}/#{y}")
          end
        }
      end
    }
    executeCommand("svn commit l10n-kde4-stable")
    
  end
end

def printHelp
  print "--release      start a release of KOffice"
  print "--test-l10n    test that l10n packages build"
  print "--branch-l10n  branch l10n of KOffice"
end

if( ARGV.size == 0 )
  printHelp
else
  what = ARGV[0]
  ARGV.clear
  if( what == "--release" )
    ReleaseKoffice.new
  elsif( what == "--test-l10n")
    TestL10n.new
  elsif( what == "--branch-l10n")
    BranchL10n.new
  else
    puts "Unknown argument: #{ARGV[0]}"
    printHelp
  end
end

