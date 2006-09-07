#!/usr/local/bin/ruby -w

# system_extensions.rb
#
#  Created by James Edward Gray II on 2006-06-14.
#  Copyright 2006 Gray Productions. All rights reserved.
#
#  This is Free Software.  See LICENSE and COPYING for details.

class HighLine
  module SystemExtensions
    module_function
    
    #
    # This section builds character reading and terminal size functions
    # to suit the proper platform we're running on.  Be warned:  Here be
    # dragons!
    #
    begin
      require "Win32API"       # See if we're on Windows.

      CHARACTER_MODE = "Win32API"    # For Debugging purposes only.

      #
      # Windows savvy getc().
      # 
      # *WARNING*:  This method ignores <tt>input</tt> and reads one
      # character from +STDIN+!
      # 
      def get_character( input = STDIN )
        Win32API.new("crtdll", "_getch", [ ], "L").Call
      end

      # A Windows savvy method to fetch the console columns, and rows.
      def terminal_size
        m_GetStdHandle               = Win32API.new( 'kernel32',
                                                     'GetStdHandle',
                                                     ['L'],
                                                     'L' )
        m_GetConsoleScreenBufferInfo = Win32API.new(
          'kernel32', 'GetConsoleScreenBufferInfo', ['L', 'P'], 'L'
        )

        format        = 'SSSSSssssSS'
        buf           = ([0] * format.size).pack(format)
        stdout_handle = m_GetStdHandle.call(0xFFFFFFF5)
        
        m_GetConsoleScreenBufferInfo.call(stdout_handle, buf)
        bufx, bufy, curx, cury, wattr,
        left, top, right, bottom, maxx, maxy = buf.unpack(format)
        return right - left + 1, bottom - top + 1
      end
    rescue LoadError             # If we're not on Windows try...
      begin
        require "termios"    # Unix, first choice.

        CHARACTER_MODE = "termios"    # For Debugging purposes only.

        #
        # Unix savvy getc().  (First choice.)
        # 
        # *WARNING*:  This method requires the "termios" library!
        # 
        def get_character( input = STDIN )
          old_settings = Termios.getattr(input)

          new_settings                     =  old_settings.dup
          new_settings.c_lflag             &= ~(Termios::ECHO | Termios::ICANON)
          new_settings.c_cc[Termios::VMIN] =  1

          begin
            Termios.setattr(input, Termios::TCSANOW, new_settings)
            input.getc
          ensure
            Termios.setattr(input, Termios::TCSANOW, old_settings)
          end
        end
      rescue LoadError         # If our first choice fails, default.
        CHARACTER_MODE = "stty"    # For Debugging purposes only.

        #
        # Unix savvy getc().  (Second choice.)
        # 
        # *WARNING*:  This method requires the external "stty" program!
        # 
        def get_character( input = STDIN )
          state = `stty -g`

          begin
            system "stty raw -echo cbreak"
            input.getc
          ensure
            system "stty #{state}"
          end
        end
      end
      
      # A Unix savvy method to fetch the console columns, and rows.
      def terminal_size
       `stty size`.split.map { |x| x.to_i }.reverse
      end
    end
  end
end
