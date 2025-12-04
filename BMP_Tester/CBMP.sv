class CBMP;
    byte bmpHeader[54];
    byte bmpImgData[640*480*3];

    int fd; // file descriptor
    string fileName;
    function new(string fileName, string mode);
        open(fileName, mode);
    endfunction

    function int open(string fileName, string mode);
        fd = $fopen(fileName, mode);
        if (!fd) begin
            $display("[%s] File Open Failed!, Simulation Finished.", fileName);
        end else begin
            $display("[%s] File Opened!", fileName);
        end
        return fd;
    endfunction

    function void close;
        $fclose(fd);
        $display("[%s] File Closed", fileName);
    endfunction

    function int read();
        int size = 0;
        size = $fread(bmpHeader, fd);
        $display("[%s] bmpHeader is read. Size : %0d", fileName, size);

        size = $fread(bmpImgData, fd);
        $display("[%s] bmpImgData is read. Size : %0d", fileName, size);
    endfunction

    function int write(byte imgData[], int size);
        for (int i = 0; i < size; i++) begin
            $fwrite(fd, "%c", imgData[i]);
        end
    endfunction

    function void flush();
        $fflush(fd);
    endfunction
endclass