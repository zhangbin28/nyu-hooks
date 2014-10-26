function res = imdb_eval_nyud2_region(cls, boxes, imdb)
  [~, clsId] = ismember(cls, imdb.classes);

  % Load the ground truth structures, for the imdb
  parfor i = 1:length(imdb.image_ids),
    roidb = imdb.roidb_func(imdb, i);
    roi = roidb.rois(i);

    % Do non max suppression
    sp2reg = roi.sp2reg(roi.gt == 0, :);
    bbox = roi.boxes(roi.gt == 0, :);
    [iu, ~, ~, ~] = compute_region_overlap(roi.sp, sp2reg, sp2reg);
    assert(isequal(boxes{i}(:,1:4), bbox));
    sc = boxes{i}(:,end);
    pick = nmsOverlap(iu, sc, nms_thresh);
    sc = sc(pick);
    bbox = bbox(pick, :);
    sp2reg = sp2reg(pick, :);

    % Benchmark this image
    gt_sp2reg = roi.sp2reg(roi.class == clsId);
    [iu_gt, ~, ~, ~] = compute_region_overlap(roi.sp, sp2reg, gt_sp2reg);
    [tp{i} fp{i} sc{i} numInst(i)] = instBenchImg(struct('sc', sc), struct('diff', zeros(1, size(gt_sp2reg,1))), [], iu_gt);
  end

  [prec, rec, ap, thresh] = instBench([], [], [], tp, fp, sc, numInst);
  res.recall = rec;
  res.prec = prec;
  res.ap = ap;
  res.ap_auc = ap;
  res.thresh = thresh;

  % Plot the precision recall curve
  figure(1);
  plot(res.recall, res.prec);
  grid on; ylim([0 1]); xlim([0 1]);
  title(sprintf('%s  AP = %0.3f', cls, res.ap));
  res.plotHandle = gcf;
end