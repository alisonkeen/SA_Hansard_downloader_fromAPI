
# Scraper to download SA Hansard XML files using API
# 
# In order to facilitate automatically downloading each day's hansard
# without having to manually download and save each day
# 
# This version of code hacked together by Alison Keen Nov 2016
#
# SA Parliament Hansard API Docs are here: 
# 
# https://parliament-api-docs.readthedocs.io/en/latest/south-australia/#read-data 
#
# Apologies for flagrant violation of coding conventions.
# I think I realised halfway through this one you're supposed to use
# camelCase for variables... oops 

require 'scraperwiki'
require 'json'
require 'fileutils'

# from Hansard server content-type is text/html, attachment is xml

$debug = FALSE
$csvoutput = FALSE
$sqloutput = TRUE

module JSONDownloader

  # The URLs to access the API... 
  @jsonDownloadYearURL = "https://hansardpublic.parliament.sa.gov.au/_vti_bin/Hansard/HansardData.svc/GetYearlyEvents/"

  @jsonDownloadTocUrl = "https://hansardpublic.parliament.sa.gov.au/_vti_bin/Hansard/HansardData.svc/GetByDate"
 
  # @jsonDownloadTocUrl = "http://pipeproject.info/date/GetByDate"


  def JSONDownloader.downloadAllFragments(year) 
  
    #Annual Index is a special case - different API URL  
    annualIndexFilename = downloadAnnualIndex(year)

    downloadEachToc(annualIndexFilename) 


      # then we read and load the JSON
      # and request each fragment for each day... 
#       downloadToc(toc_saphFilename) 

      # then get the hash of fragments from each TOC file... 

        # and download each one. 

  end

  # read horrible JSON file and get toc filenames
  def JSONDownloader.downloadEachToc(annualIndexFilename)

    puts "Parsing annual index #{annualIndexFilename}" if $debug
    rawJSON = File.read(annualIndexFilename)
    loadedJSON = JSON.load rawJSON # Why is this returning a String!?
    parsedJSON = JSON.load loadedJSON # Needs to be parsed twice (!?)

    parsedJSON.each do |event| # for-each-date
      puts event.keys if $debug
      record_date =  event['date'].to_s

      puts "Available for..." + record_date if $debug

      event['Events'].each do |record| # for each transcript on date
        puts "\nEvent: " + record.to_s if $debug
        saphFilename = record['TocDocId'].to_s
        saphChamber = record['Chamber'].to_s
   

        if saphFilename.empty?
          puts " Keys in record: " if $debug
          puts record.keys if $debug
          puts " -- end record of transcript -- " if $debug
        else
          #Output is here: 
          puts "\"#{saphFilename}\",\"#{record_date}\",\"#{saphChamber}\"" if $csvoutput

          data = {
            filename: saphFilename,
            date: record_date,
            house: saphChamber
          }

          ScraperWiki.save_sqlite([:filename], data) if $sqloutput
        end


      end # end for-each-transcript-on-date block
      
    end # end for-each-date block

  end

  # Puts the raw, no-line-breaks JSON into a file and
  # returns the file name.
  def JSONDownloader.downloadAnnualIndex(year)

    urlToLoad = @jsonDownloadYearURL + year.to_s
    filename = "downloaded/#{year.to_s}_hansard.json"
    
    puts "downloading file" if $debug  
    `curl --silent --output #{filename} "#{urlToLoad}"`
 
    filename # The output of the method. ruby doesn't use 'return'
  end




end #end JSONDownloader class

puts "\"Filename\",\"date\",\"house\"" if $csvoutput

year = Date.today.year

while year > 2006
   JSONDownloader.downloadAllFragments(year)
   year -= 1

end




