import ballerina/io;

// This function returns a `DelimitedRecordChannel` from a given file location.The encoding is a character representation (i.e., UTF-8 ASCCI) of the content in the file. The `rs` annotation defines a record seperator (e.g., a new line) and the `fs` annotation is a field seperator (e.g., a comma).
function getFileRecordChannel(string filePath, io:Mode permission, string encoding,
                              string rs, string fs) returns (io:DelimitedTextRecordChannel) {
    io:ByteChannel channel = io:openFile(filePath, permission);
    // Create a `character channel` from the `byte channel` to read content as text.
    io:CharacterChannel characterChannel = new(channel, encoding);
    // Convert the `character channel` to a `record channel`
    //to read the content as records.
    io:DelimitedTextRecordChannel delimitedRecordChannel = new(characterChannel, rs = rs, fs = fs);
    return delimitedRecordChannel;
}

// This function reads the next record from the channel.
function readNext(io:DelimitedTextRecordChannel channel) returns (string[]) {
    match channel.getNext() {
        string[] records => {
            return records;
        }
        error err => {
            throw err.cause but { () => err };
        }

    }
}

// This function writes the next record to the channel.
function write(io:DelimitedTextRecordChannel channel, string[] records) {
    error? err = channel.write(records);
    match err {
        error e => throw e.cause but { () => e };
        () => {}
    }
}

// This function processes the `.CSV` file and writes content back as text with the `|` delimiter.
function process(io:DelimitedTextRecordChannel srcRecordChannel, io:DelimitedTextRecordChannel dstRecordChannel) {
    try {
        //Read all the records from the provided file until there are no more records.
        while (srcRecordChannel.hasNext()) {
            // Read the records.
            string[] records = readNext(srcRecordChannel);
            // Write the records.
            write(dstRecordChannel, records);
        }
    } catch (error err) {
        throw err;
    }
}

//Specify the location of the `.CSV` file and the text file. 
function main(string... args) {
    string srcFileName = "./files/sample.csv";
    string dstFileName = "./files/sampleResponse.txt";
    // The record separator of the `.CSV` file is a
    // new line, and the field separator is a comma (,).
    io:DelimitedTextRecordChannel srcRecordChannel =
        getFileRecordChannel(srcFileName, io:READ, "UTF-8", "\\r?\\n", ",");
    //The record separator of the text file
    //is a new line, and the field separator is a pipe (|).
    io:DelimitedTextRecordChannel dstRecordChannel =
        getFileRecordChannel(dstFileName, io:WRITE, "UTF-8", "\n", "|");
    try {
        io:println("Start processing the CSV file from " + srcFileName + " to the text file in " + dstFileName);
        process(srcRecordChannel, dstRecordChannel);
        io:println("Processing completed. The processed file is located in ", dstFileName);
    } catch (error err) {
        io:println("An error occurred while processing the records. ", err.message);
    } finally {
        //Close the text record channel.
        match srcRecordChannel.close() {
            error sourceCloseError => {
                io:println("Error occured while closing the channel: ", sourceCloseError.message);
            }
            () => {
                io:println("Source channel closed successfully.");
            }
        }
        match dstRecordChannel.close() {
            error destinationCloseError => {
                io:println("Error occured while closing the channel: ", destinationCloseError.message);
            }
            () => {
                io:println("Destination channel closed successfully.");
            }
        }
    }
}
