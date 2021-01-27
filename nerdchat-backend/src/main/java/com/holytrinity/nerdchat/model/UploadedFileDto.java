package com.holytrinity.nerdchat.model;

import com.holytrinity.nerdchat.entity.UploadedFile;
import com.holytrinity.nerdchat.entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.beans.BeanUtils;

import javax.persistence.*;
import java.util.Date;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class UploadedFileDto {
    private int id;
    private UploadedFileType type;
    private String contentType;

    private long size_bytes;
    private String checksum;
    private String name;

    private Date uploadedAt;

    public static UploadedFileDto from(UploadedFile file) {
        var obj = new UploadedFileDto();
        BeanUtils.copyProperties(file, obj);
        return obj;
    }


}
