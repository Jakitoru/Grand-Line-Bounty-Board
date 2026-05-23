const { NodeSSH } = require('node-ssh');
const { execSync } = require('child_process');
const fs = require('fs');

const ssh = new NodeSSH();

const host = '20.6.11.137';
const username = 'azureuser';
const password = 'Deocomkdau2107@';
const remoteDir = '/home/azureuser/one-piece-app';
const localArchive = 'app.tar.gz';

async function deploy() {
  try {
    console.log('1. Đang nén thư mục dự án (bỏ qua node_modules và .next)...');
    execSync('tar -czf app.tar.gz --exclude=node_modules --exclude=.next --exclude=.git .');
    console.log('Nén xong: app.tar.gz');

    console.log(`2. Đang kết nối SSH tới ${username}@${host}...`);
    await ssh.connect({
      host: host,
      username: username,
      password: password,
    });
    console.log('Kết nối SSH thành công!');

    console.log('3. Đang thiết lập máy chủ và tải code lên...');
    await ssh.execCommand(`mkdir -p ${remoteDir}`);
    
    // Upload file
    await ssh.putFile(localArchive, `${remoteDir}/app.tar.gz`);
    console.log('Upload mã nguồn thành công!');

    console.log('4. Cài đặt Docker (nếu chưa có) và khởi chạy ứng dụng...');
    
    const setupScript = `
      cd ${remoteDir}
      tar -xzf app.tar.gz
      
      # Kiểm tra docker
      if ! command -v docker &> /dev/null; then
          curl -fsSL https://get.docker.com -o get-docker.sh
          sudo sh get-docker.sh
          sudo usermod -aG docker $USER
      fi
      
      # Chạy docker compose
      # Azure VM thường chạy trên mạng public, tốt nhất là bind thẳng port 80 cho web
      sed -i 's/"3000:3000"/"80:3000"/g' docker-compose.yml
      sudo docker compose up -d --build
    `;

    const result = await ssh.execCommand(setupScript, {
      onStdout(chunk) {
        process.stdout.write(chunk.toString('utf8'));
      },
      onStderr(chunk) {
        process.stderr.write(chunk.toString('utf8'));
      }
    });

    console.log('--- KẾT QUẢ TRIỂN KHAI ---');
    console.log('Mã lỗi:', result.code);
    if (result.code === 0) {
      console.log('🎉 Đã deploy thành công!');
      console.log(`Hãy mở trình duyệt và truy cập: http://${host}`);
    } else {
      console.error('❌ Có lỗi xảy ra trong quá trình deploy.');
    }

  } catch (err) {
    console.error('Lỗi nghiêm trọng:', err);
  } finally {
    ssh.dispose();
    if (fs.existsSync(localArchive)) {
      fs.unlinkSync(localArchive);
    }
  }
}

deploy();
