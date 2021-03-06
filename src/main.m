clear;
%Compile code for face FIRST!
addpath('./face_detection');
addpath('./max_flow');
addpath('./face_plusplus');
addpath('./TPS');

srcImgFile = '../data/test/7.jpg';
dstImgFile = '../data/test/8.jpg';

%read image
im_src = imread(srcImgFile);
im_dst = imread(dstImgFile);
subplot(1,3,1);
imshow(im_src);
subplot(1,3,2);
imshow(im_dst);

im_src = imresize(im_src, [size(im_dst, 1), size(im_dst, 2)]);
imresize_src_name = 'temp_resize_src.jpg';
imwrite(im_src, imresize_src_name);


%detect face
%[point_src] = detectSingleFace(im_src);
[point_src] = detectSingleFacePlusPlus(imresize_src_name);
%get mask
point_src_M = point_src(convhull(point_src),:);
mask_src = roipoly(im_src,point_src_M(:,1),point_src_M(:,2));

%read image
im_dst = imread(dstImgFile);
%detect face
%[point_dst] = detectSingleFace(im_dst);
[point_dst] = detectSingleFacePlusPlus(dstImgFile);
%get mask
point_dst_M = point_dst(convhull(point_dst),:);
mask_dst = roipoly(im_dst,point_dst_M(:,1),point_dst_M(:,2));

%{
%get transform matrix
tform = fitgeotrans(point_src,point_dst,'affine');
%transform src image to align with dst image
im_src_warp = imwarp(im_src,tform,'OutputView',imref2d(size(im_dst)));
im_dst_warp = im_dst;
mask_src_warp = imwarp(mask_src,tform,'OutputView',imref2d(size(im_dst)));
mask_dst_warp = mask_dst;
%}

%Morph the src image

[im_src_warp, im_dst_warp, mask_src_warp, mask_dst_warp] = morph_tps_wrapper(uint8(im_src), uint8(im_dst), point_src, point_dst,1,0,1, mask_src, mask_dst);
mask_dst_warp = mask_dst_warp(:,:,1);
mask_src_warp = mask_src_warp(:,:,1);
%Find optimal seam
[~,labels] = optimalSeamSearch(im_src_warp, im_dst_warp, mask_dst_warp, mask_src_warp);
innerR = uint8(im_src_warp).*repmat(uint8(labels),[1,1,3]);
innerOri = uint8(im_dst_warp).*repmat(uint8(labels), [1 1 3]);
innerR = changeLumination(innerOri, innerR);

%blending
%im_src_warp = innerR + uint8(im_src_warp).*repmat(uint8(1 - labels),[1,1,3]);
subplot(1,3,3)
R = PoissonBlending(im_src_warp,im_dst_warp, labels);
imshow(uint8(R));
%figure
%imshow(uint8(R))
%{
subplot(1,2,1)
R = uint8(im_src_warp).*repmat(uint8(labels),[1,1,3]) + uint8(im_dst_warp).*repmat(uint8(1-labels), [1 1 3]);
imshow(R)
%}


%{
figure;
hold on;
imagesc(im_dst); axis image; axis off; drawnow; 1, 0
plot(point_dst(:,1),point_dst(:,2),'g.','markersize',15);
hold off;
%}